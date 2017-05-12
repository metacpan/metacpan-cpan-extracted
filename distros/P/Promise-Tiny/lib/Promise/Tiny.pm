package Promise::Tiny;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Scalar::Util qw(blessed);
use Exporter qw(import);

our @EXPORT_OK = qw(promise);

sub promise {
    return __PACKAGE__->new(@_);
}

#### constructor ####

sub new {
    my ($class, $code) = @_;
    my $self = bless {}, $class;
    eval {
        $code->(
            sub { $self->_resolve(@_); },
            sub { $self->_reject(@_); },
        );
    };
    if ($@) {
        $self->_reject($@);
    }
    return $self;
}

#### instance methods ####

sub _resolve {
    my ($self, $value) = @_;
    unless ($self->{_fulfilled} || $self->{_rejected}) {
        $self->{_fulfilled} = 1;
        $self->{_fulfilled_value} = $value;
        if ($self->{on_fulfilled}) {
            $self->{on_fulfilled}->($value);
        }
    }
}

sub _reject {
    my ($self, $reason) = @_;
    unless ($self->{_fulfilled} || $self->{_rejected}) {
        $self->{_rejected} = 1;
        $self->{_rejected_reason} = $reason;
        if ($self->{on_rejected}) {
            $self->{on_rejected}->($reason);
        }
    }
}

sub then {
    my ($self, $on_fulfilled, $on_rejected) = @_;
    my $class = ref $self;
    return $class->new(sub {
        my ($resolve, $reject) = @_;

        my $handler_wrapper = sub {
            my ($handler) = @_;
            return sub {
                my ($value) = @_;
                my $resolved_value = eval { $handler->($value); };
                if ($@) {
                    $reject->($@);
                } elsif (_is_promise($resolved_value)) {
                    $resolved_value->then(sub {
                        my ($value) = @_;
                        $resolve->($value);
                    }, sub {
                        my ($reason) = @_;
                        $reject->($reason);
                    });
                } else {
                    $resolve->($resolved_value);
                }
            };
        };

        if ($on_fulfilled) {
            $self->{on_fulfilled} = $handler_wrapper->($on_fulfilled);
            if ($self->{_fulfilled}) {
                $self->{on_fulfilled}->($self->{_fulfilled_value});
            }
        }
        if ($on_rejected) {
            $self->{on_rejected} = $handler_wrapper->($on_rejected);
            if ($self->{_rejected}) {
                $self->{on_rejected}->($self->{_rejected_reason});
            }
        }
    });
}

sub catch {
    my ($self, $on_rejected) = @_;
    return $self->then(
        sub {
            my ($value) = @_;
            return $value;
        },
        $on_rejected
    );
}

#### static methods ####

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
        for my $promise (@promises) {
            $promise->then(sub {
                my ($value) = @_;
                $unresolved_size--;
                if ($unresolved_size <= 0) {
                    $resolve->([ map { $_->{_fulfilled_value} } @promises ]);
                }
            }, sub {
                my ($reason) = @_;
                $reject->($reason);
            });
        }
    });
}

sub race {
    my ($class, $iterable) = @_;
    my @promises = map { _is_promise($_) ? $_ : $class->resolve($_) } @$iterable;

    return $class->new(sub {
        my ($resolve, $reject) = @_;
        for my $promise (@promises) {
            $promise->then(sub {
                my ($value) = @_;
                $resolve->($value);
            }, sub {
                my ($reason) = @_;
                $reject->($reason);
            });
        }
    });
}

#### utility ####

sub _is_promise {
    my ($value) = @_;
    return blessed $value && $value->isa(__PACKAGE__);
}

1;

__END__

=encoding utf-8

=head1 NAME

Promise::Tiny - A promise implementation written in Perl

=head1 SYNOPSIS

    use Promise::Tiny;

    my $promise = Promise::Tiny->new(sub {
        my ($resolve, $reject) = @_;
        some_async_process(..., sub { # callback.
            ...
            if ($error) {
                $reject->($error);
            } else {
                $resolve->('success value');
            }
        });
    })->then(sub {
        my ($value) = @_;
        print $value # -> success value
    }, sub {
        my ($error) = @_;
        # handle error
    });

=head1 DESCRIPTION

Promise::Tiny is tiny promise implementation.
Promise::Tiny has same interfaces as ES6 Promise.

=head1 LICENSE

Copyright (C) hatz48.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

hatz48 E<lt>hatz48@hatena.ne.jpE<gt>

=cut

