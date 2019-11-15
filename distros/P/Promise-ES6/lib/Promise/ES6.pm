package Promise::ES6;

use strict;
use warnings;

our $VERSION = '0.10';

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

This module provides a Perl implementation of L<promises|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>, a useful pattern
for coordinating asynchronous tasks.

Unlike most other promise implementations on CPAN, this module
mimics ECMAScript 6’s L<Promise|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>
class. As the SYNOPSIS above shows, you can thus use patterns from JavaScript
in Perl with only minimal changes needed to accommodate language syntax.

This is a rewrite of an earlier module, L<Promise::Tiny>. It fixes several
bugs and superfluous dependencies in the original.

=head1 INTERFACE NOTES

=over

=item * Promise resolutions and rejections accept exactly one argument,
not a list.

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

=head1 SYNCHRONOUS OPERATION

In JavaScript, the following …

    Promise.resolve().then( () => console.log(1) );
    console.log(2);

… will log C<2> then C<1> because JavaScript’s C<then()> defers execution
of its callbacks until the end of the current iteration through JavaScript’s
event loop.

Perl, of course, has no built-in event loop. This module’s C<then()> method,
thus, when called on a promise that is already
“settled” (i.e., not pending), will run the appropriate callback
I<immediately>. That means that this:

    Promise::ES6->resolve(0)->then( sub { print 1 } );
    print 2;

… will print C<12> instead of C<21>.

This is an intentional divergence from
L<the Promises/A+ specification|https://promisesaplus.com/#point-34>.
A key advantage of this design is that Promise::ES6 instances can abstract
over whether a given function works synchronously or asynchronously.

If you want a Promises/A+-compliant implementation, look at
L<Promise::ES6::IOAsync>, L<Promise::ES6::AnyEvent>, or one of the alternatives
that that module’s documentation suggests.

=head1 CANCELLATION

Promises have never provided a standardized solution for cancellation—i.e.,
aborting an in-process operation. So, if you need this functionality, you’ll
have to implement it yourself. Two ways of doing this are:

=over

=item * Subclass Promise::ES6 and provide cancellation logic in your
subclass. See L<DNS::Unbound::AsyncQuery>’s implementation for an
example of this.

=item * Implement the cancellation on the object that creates your promises.
This is probably the more straightforward approach but requires that there
be some object or ID besides the promise that uniquely identifies the action
to be canceled. See L<Net::Curl::Promiser> for an example of this approach.

=back

You’ll need to decide if it makes more sense for your application to leave
a canceled query in the “pending” state or to resolve or reject it.
All things being equal, I feel the first approach is the most intuitive.

=head1 MEMORY LEAKS

It’s easy to create inadvertent memory leaks using promises in Perl.
Here are a few “pointers” (heh) to bear in mind:

=over

=item * As of version 0.07, any Promise::ES6 instances that are created while
C<$Promise::ES6::DETECT_MEMORY_LEAKS> is set to a truthy value are
“leak-detect-enabled”, which means that if they survive until their original
process’s global destruction, a warning is triggered.

=item * If your application needs recursive promises (e.g., to poll
iteratively for completion of a task), the C<current_sub> feature (i.e.,
C<__SUB__>) may help you avoid memory leaks.

=item * Garbage collection before Perl 5.18 seems to have been buggy.
If you work with such versions and end up chasing leaks,
try manually deleting as many references/closures as possible. See
F<t/race_success.t> for a notated example.

You may also (counterintuitively, IMO) find that this:

    my ($resolve, $reject);

    my $promise = Promise::ES6->new( sub { ($resolve, $reject) = @_ } );

    # … etc.

… works better than:

    my $promise = Promise::ES6->new( sub {
        my ($resolve, $reject) = @_;

        # … etc.
    } );

=back

=head1 SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
L<this one|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>.

Promise::ES6 serves much the same role as L<Future> but exposes
a standard, minimal, cross-language API rather than a proprietary (large) one.

CPAN contains a number of other modules that implement promises. I think
mine is the nicest :), but YMMV. Enjoy!

=head1 LICENSE & COPYRIGHT

Copyright 2019 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.

=cut

our $DETECT_MEMORY_LEAKS;

# "$value_sr" => $value_sr
our %_UNHANDLED_REJECTIONS;

sub new {
    my ($class, $cr) = @_;

    die 'Need callback!' if !$cr;

    my $value;
    my $value_sr = bless \$value, _PENDING_CLASS();

    my @children;

    my $self = bless {
        _pid => $$,
        _children => \@children,
        _value_sr => $value_sr,
        _detect_leak => $DETECT_MEMORY_LEAKS,
    }, $class;

    my $suppress_unhandled_rejection_warning = 1;

    # NB: These MUST NOT refer to $self, or else we can get memory leaks
    # depending on how $resolver and $rejector are used.
    my $resolver = sub {
        $$value_sr = $_[0];
        bless $value_sr, _RESOLUTION_CLASS();
        _propagate_if_needed( $value_sr, \@children );
    };

    my $rejecter = sub {
        $$value_sr = $_[0];
        bless $value_sr, _REJECTION_CLASS();

        if (!$suppress_unhandled_rejection_warning) {
            $_UNHANDLED_REJECTIONS{$value_sr} = $value_sr;
        }

        _propagate_if_needed( $value_sr, \@children );
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
    my ($value_sr, $children_ar) = @_;

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

            # It may not be necessary to empty out @$children_ar, but
            # let’s do so anyway so Perl will delete references ASAP.
            # It’s safe to do so because from here on $value_sr is
            # no longer a pending value.
            for my $subpromise (splice @$children_ar) {
                $subpromise->_finish($value_sr);
            }
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
        _children => [],

        _on_finish => [ $on_resolve, $on_reject ],

        _detect_leak => $DETECT_MEMORY_LEAKS,
    };

    bless $new, (ref $self);

    if ($self->_is_completed()) {
        $new->_finish( $self->{'_value_sr'} );
    }
    else {
        push @{ $self->{'_children'} }, $new;
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

    # A promise that new() created won’t have on-finish callbacks,
    # but a promise that came from then/catch/finally will.
    # It’s a good idea to delete _on_finish in order to trigger garbage
    # collection as soon and as reliably as possible. It’s safe to do so
    # because _finish() is only called once.
    my $callback = delete $self->{'_on_finish'};

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
        @{$self}{ qw( _value_sr  _children ) },
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

    my ($resolve, $reject);

    # Perl 5.16 and earlier leak memory when the callbacks are handled
    # inside the closure here.
    my $new = $class->new(sub {
        ($resolve, $reject) = @_;
    } );

    my $is_done;

    for my $promise (@promises) {
        last if $is_done;

        $promise->then(sub {
            return if $is_done;
            $is_done = 1;

            $resolve->($_[0]);

            # Proactively eliminate references:
            $resolve = $reject = undef;
        }, sub {
            return if $is_done;
            $is_done = 1;

            $reject->($_[0]);

            # Proactively eliminate references:
            $resolve = $reject = undef;
        });
    }

    return $new;
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
