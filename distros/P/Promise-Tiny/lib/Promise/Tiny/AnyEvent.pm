package Promise::Tiny::AnyEvent;
use strict;
use warnings;

use parent 'Promise::Tiny';
use AnyEvent;
use Exporter qw(import);

our @EXPORT_OK = qw(promise);

sub promise {
    return __PACKAGE__->new(@_);
}

sub await {
    my ($self) = @_;
    my $cv = AnyEvent->condvar;
    $self->then(
        sub {
            my ($value) = @_;
            $cv->send($value);
        },
        sub {
            my ($reason) = @_;
            $cv->croak($reason);
        }
    );
    return $cv->recv;
}

1;
