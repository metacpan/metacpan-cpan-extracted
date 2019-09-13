package Promise::ES6;

use strict;
use warnings;

our $VERSION = '0.06';

=encoding utf-8

=head1 NAME

Promise::ES6 - ES6-style promises in Perl

=head1 SYNOPSIS

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

=head1 SEE ALSO

If you’re not sure of what promises are, there are several good
introductions to the topic. You might start with
L<this one|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>.

=cut

our $_SUPPRESS_UNHANDLED_REJECTION_WARNING;

sub new {
    my ($class, $cr) = @_;

    my $self = bless { _suppress_uncaught_reject_warn => 0 }, $class;

    local $_SUPPRESS_UNHANDLED_REJECTION_WARNING = 1;

    my $resolver = sub { $self->_finish( resolve => $_[0]) };
    my $rejecter = sub { $self->_finish( reject => $_[0]) };

    local $@;
    if ( !eval { $cr->( $resolver, $rejecter ); 1 } ) {
        local $_SUPPRESS_UNHANDLED_REJECTION_WARNING = 0;
        $self->_finish( reject => $@ );
    }

    return $self;
}

sub then {
    my ($self, $on_resolve, $on_reject) = @_;

    my $new = {
        _on_resolve => $on_resolve,
        _on_reject => $on_reject,
        _warned_unhandled_reject => $self->{'_warned_unhandled_reject'},
    };

    bless $new, (ref $self);

    if ($self->{'_finished_how'}) {
        $new->_finish( $self->{'_finished_how'} => $self->{'_value'} );
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

sub _finish {
    my ($self, $how, $value) = @_;

    die "$self already finished!" if $self->{'_finished_how'};

    local $@;

    if ($self->{"_on_$how"}) {
        if ( eval { $value = $self->{"_on_$how"}->($value); 1 } ) {

            # This is here so that a rejection that’s caught
            # after-the-fact will “reset”. That way further promises
            # in the chain will warn() on rejection.
            delete $self->{'_warned_unhandled_reject'};

            $how = 'resolve';
        }
        else {
            $how = 'reject';
            $value = $@;
        }
    }

    my $repromise_if_needed;
    $repromise_if_needed = sub {
        my ($repromise_how, $repromise_value) = @_;

        if (eval { $repromise_value->isa(__PACKAGE__) }) {
            $self->{'_unresolved_value'} = $repromise_value;

            $repromise_value->then(
                sub { $repromise_if_needed->( resolve => $_[0]) },
                sub {
                    $repromise_if_needed->( reject => $_[0]);
                },
            );
        }
        else {
            $self->{'_value'} = $repromise_value;
            $self->{'_finished_how'} = $repromise_how;

            $_->_finish($repromise_how, $repromise_value) for @{ $self->{'_dependents'} };

            if ($repromise_how eq 'reject' && !@{ $self->{'_dependents'} }) {
                if (!$_SUPPRESS_UNHANDLED_REJECTION_WARNING) {
                    $self->{'_warned_unhandled_reject'} ||= do {
                        my $ref = ref $self;
                        warn "$ref: Unhandled rejection: $repromise_value";
                    };
                }
            }
        }
    };

    $repromise_if_needed->($how, $value);

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

    return $class->new(sub {
        my ($resolve, $reject) = @_;
        my $unresolved_size = scalar(@promises);

        if ($unresolved_size) {
            for my $promise (@promises) {
                $promise->then(sub {
                    my ($value) = @_;
                    $unresolved_size--;
                    if ($unresolved_size <= 0) {
                        $resolve->([ map { $_->{_value} } @promises ]);
                    }
                }, sub {
                    my ($reason) = @_;
                    $reject->($reason);
                });
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

1;
