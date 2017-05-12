package Net::Signalet::Server;
use strict;
use warnings;

use parent qw(Net::Signalet);


sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 && ref($args[0]) eq 'HASH' ? %{$args[0]} : @args;

    $args{listen} ||= 1;

    $class->SUPER::_init(%args);

    my $sock = IO::Socket::INET->new(
        Proto     => 'tcp',
        LocalPort => $args{sport} || 14550,
        LocalAddr => $args{saddr} || undef,
        Listen    => $args{listen},
        Timeout   => $args{timeout} || 180,
        ReuseAddr => $args{reuse} || 0,
    ) or die $!;

    $sock->listen or die $!;
    my $csock = $sock->accept; # only for one client

    my $self = bless {
        worker_pid => undef,
        sock  => $csock,
        ssock => $sock,
    }, $class;
    return $self;
}

sub close {
    my ($self) = @_;
    $self->SUPER::close;
    close $self->{ssock};
}

1;
