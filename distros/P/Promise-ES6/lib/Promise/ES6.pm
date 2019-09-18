package Promise::ES6;

use strict;
use warnings;

our $VERSION = '0.07';

use constant {

    # These aren’t actually defined.
    _RESOLUTION_CLASS => 'Promise::ES6::_RESOLUTION',
    _REJECTION_CLASS => 'Promise::ES6::_REJECTION',
    _PENDING_CLASS => 'Promise::ES6::_PENDING',
};

=encoding utf-8

=head1 NAME

Promise::ES6 - ES6-style promises in Perl

=head1 SYNOPSIS

    $Promise::ES6::DETECT_MEMORY_LEAKS = 1;

    my $promise = Promise::ES6->new( sub {
        my ($resolve_cr, $reject_cr) = @_;

        # ..
    } );

    my $promise2 = $promise->then( sub { .. }, sub { .. } );

    my $promise3 = $promise->catch( sub { .. } );

    my $promise4 = $promise->finally( sub { .. } );

    my $resolved = Promise::ES6->resolve(5);
    my $rejected = Promise::ES6->reject('nono');

    my $all_promise = Promise::ES6->all( \@promises );

    my $race_promise = Promise::ES6->race( \@promises );

=head1 DESCRIPTION

This is a rewrite of L<Promise::Tiny> that implements fixes for
certain bugs that proved hard to fix in the original code. This module
also removes superfluous dependencies on L<AnyEvent> and L<Scalar::Util>.

The interface is the same, except:

=over

=item * Promise resolutions and rejections accept exactly one argument,
not a list. (This accords with the standard.)

=item * A C<finally()> method is defined.

=item * Unhandled rejections are reported via C<warn()>. (See below
for details.)

=back

=head1 COMPATIBILITY

Right now this doesn’t try for interoperability with other promise
classes. If that’s something you want, make a feature request.

=head1 UNHANDLED REJECTIONS

As of version 0.05, unhandled rejections prompt a warning I<only> if one
of the following is true:

=over

=item 1) The unhandled rejection happens outside of the constructor.

=item 2) The unhandled rejection happens via an uncaught exception
(even within the constructor).

=back

=head1 LEAK DETECTION

It’s easy to create inadvertent memory leaks using promises.
As of version 0.07, any Promise::ES6 instances that are created while
C<$Promise::ES6::DETECT_MEMORY_LEAKS> is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered.

B<NOTE:> If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), C<use feature 'current_sub'>
may help you avoid memory leaks.

=head1 SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
L<this one|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>.

Promise::ES6 serves much the same role as L<Future> but exposes
a standard, cross-language API rather than a proprietary one.

CPAN contains a number of other modules that implement promises.
Promise::ES6’s distinguishing features are simplicity and lightness.
By design, it implements B<just> the standard Promise API and doesn’t
assume you use, e.g., L<AnyEvent>.

=cut

our $DETECT_MEMORY_LEAKS;

# "$value_sr" => $value_sr
our %_UNHANDLED_REJECTIONS;

sub new {
    my ($class, $cr) = @_;

    die 'Need callback!' if !$cr;

    my $value;
    my $value_sr = bless \$value, _PENDING_CLASS();

    my @dependents;

    my $self = bless {
        _pid => $$,
        _dependents => \@dependents,
        _value_sr => $value_sr,
        _detect_leak => $DETECT_MEMORY_LEAKS,
    }, $class;

    my $suppress_unhandled_rejection_warning = 1;

    # NB: These MUST NOT refer to $self, or else we can get memory leaks
    # depending on how $resolver and $rejector are used.
    my $resolver = sub {
        $$value_sr = $_[0];
        bless $value_sr, _RESOLUTION_CLASS();
        _propagate_if_needed( $value_sr, \@dependents );
    };

    my $rejecter = sub {
        $$value_sr = $_[0];
        bless $value_sr, _REJECTION_CLASS();

        if (!$suppress_unhandled_rejection_warning) {
            $_UNHANDLED_REJECTIONS{$value_sr} = $value_sr;
        }

        _propagate_if_needed( $value_sr, \@dependents );
    };

    local $@;
    if ( !eval { $cr->( $resolver, $rejecter ); 1 } ) {
        $$value_sr = $@;
        bless $value_sr, _REJECTION_CLASS();

        $_UNHANDLED_REJECTIONS{$value_sr} = $value_sr;
    }

    $suppress_unhandled_rejection_warning = 0;

    return $self;
}

sub _propagate_if_needed {
    my ($value_sr, $dependents_ar) = @_;

    my $propagate_cr;
    $propagate_cr = sub {
        my ($repromise_value_sr) = @_;

        if ( _is_promise($$repromise_value_sr) ) {
            my $in_reprom = $$repromise_value_sr->then(
                sub { $propagate_cr->( bless \do {my $v = $_[0]}, _RESOLUTION_CLASS ) },
                sub { $propagate_cr->( bless \do {my $v = $_[0]}, _REJECTION_CLASS ) },
            );
        }
        else {
            $$value_sr = $$repromise_value_sr;
            bless $value_sr, ref($repromise_value_sr);

            for my $subpromise (@$dependents_ar) {
                $subpromise->_finish($value_sr);
            }

            @$dependents_ar = ();
        }
    };

    $propagate_cr->($value_sr);

    return;
}

sub then {
    my ($self, $on_resolve, $on_reject) = @_;

    my $value_sr = bless( \do{ my $v }, _PENDING_CLASS() );

    my $new = {
        _pid => $$,

        _value_sr => $value_sr,
        _dependents => [],

        _parent_completion_callbacks => [ $on_resolve, $on_reject ],

        _detect_leak => $DETECT_MEMORY_LEAKS,
    };

    bless $new, (ref $self);

    if ($self->_is_completed()) {
        $new->_finish( $self->{'_value_sr'} );
    }
    else {
        push @{ $self->{'_dependents'} }, $new;
    }

    return $new;
}

sub catch { return $_[0]->then( undef, $_[1] ) }

sub finally {
    my ($self, $todo_cr) = @_;

    return $self->then( $todo_cr, $todo_cr );
}

sub _is_completed {
    return !$_[0]{'_value_sr'}->isa( _PENDING_CLASS() );
}

sub _finish {
    my ($self, $value_sr) = @_;

    die "$self already finished!" if $self->_is_completed();

    local $@;

    my $callback = $self->{'_parent_completion_callbacks'};
    $callback &&= $callback->[ $value_sr->isa( _REJECTION_CLASS() ) ? 1 : 0 ];

    # Only needed when catching, but the check would be more expensive
    # than just always deleting. So, hey.
    delete $_UNHANDLED_REJECTIONS{$value_sr};

    if ($callback) {
        my ($new_value);

        if ( eval { $new_value = $callback->($$value_sr); 1 } ) {
            # bless $self->{'_value_sr'}, _RESOLUTION_CLASS();
            bless $self->{'_value_sr'}, _RESOLUTION_CLASS() if !_is_promise($new_value);
        }
        else {
            bless $self->{'_value_sr'}, _REJECTION_CLASS();
            $_UNHANDLED_REJECTIONS{ $self->{'_value_sr'} } = $self->{'_value_sr'};
            $new_value = $@;
        }

        ${ $self->{'_value_sr'} } = $new_value;
    }
    else {
        bless $self->{'_value_sr'}, ref($value_sr);
        ${ $self->{'_value_sr'} } = $$value_sr;

        if ($value_sr->isa( _REJECTION_CLASS())) {
            $_UNHANDLED_REJECTIONS{ $self->{'_value_sr'} } = $self->{'_value_sr'};
        }
    }

    _propagate_if_needed(
        @{$self}{ qw( _value_sr  _dependents ) },
    );

    return;
}

#----------------------------------------------------------------------

sub resolve {
    my ($class, $value) = @_;

    return $class->new(sub {
        my ($resolve, undef) = @_;
        $resolve->($value);
    });
}

sub reject {
    my ($class, $reason) = @_;

    return $class->new(sub {
        my (undef, $reject) = @_;
        $reject->($reason);
    });
}

sub all {
    my ($class, $iterable) = @_;
    my @promises = map { _is_promise($_) ? $_ : $class->resolve($_) } @$iterable;

    my @value_srs = map { $_->{_value_sr} } @promises;

    return $class->new(sub {
        my ($resolve, $reject) = @_;
        my $unresolved_size = scalar(@promises);

        if ($unresolved_size) {
            for my $promise (@promises) {
                my $new = $promise->then(
                    sub {
                        $unresolved_size--;
                        if ($unresolved_size <= 0) {
                            $resolve->([ map { $$_ } @value_srs ]);
                        }
                    },
                    $reject,
                );
            }
        }
        else {
            $resolve->([]);
        }
    });
}

sub race {
    my ($class, $iterable) = @_;
    my @promises = map { _is_promise($_) ? $_ : $class->resolve($_) } @$iterable;

    return $class->new(sub {
        my ($resolve, $reject) = @_;

        my $is_done;

        for my $promise (@promises) {
            last if $is_done;

            $promise->then(sub {
                my ($value) = @_;

                return if $is_done;
                $is_done = 1;

                $resolve->($value);
            }, sub {
                my ($reason) = @_;

                return if $is_done;
                $is_done = 1;

                $reject->($reason);
            });
        }
    });
}

sub _is_promise {
    local $@;
    return eval { $_[0]->isa(__PACKAGE__) };
}

sub DESTROY {
    return if $$ != $_[0]{'_pid'};

    if ($_[0]{'_detect_leak'} && ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT') {
        warn(
            ('=' x 70) . "\n"
            . 'XXXXXX - ' . ref($_[0]) . " survived until global destruction; memory leak likely!\n"
            . ("=" x 70) . "\n"
        );
    }

    if ($_[0]{'_value_sr'}) {
        if (my $value_sr = delete $_UNHANDLED_REJECTIONS{ $_[0]{'_value_sr'} }) {
            my $ref = ref $_[0];
            warn "$ref: Unhandled rejection: $$value_sr";
        }
    }
}

1;
