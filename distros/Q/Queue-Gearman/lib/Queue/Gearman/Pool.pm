package Queue::Gearman::Pool;
use strict;
use warnings;
use utf8;

use Queue::Gearman::Socket;
use Queue::Gearman::Select;

use Class::Accessor::Lite new => 1, ro => [qw/
    servers
    timeout
    inactivity_timeout
    on_connect_do
/];

sub get {
    my ($self, $server) = @_;
    return $self->{socket}->{$server} ||= Queue::Gearman::Socket->new(
        server             => $server,
        timeout            => $self->timeout,
        inactivity_timeout => $self->inactivity_timeout,
        on_connect_do      => $self->on_connect_do,
    );
}

sub all {
    my $self = shift;
    return map { $self->get($_) } @{ $self->servers };
}

sub select :method {
    my $self = shift;
    return $self->{select} ||= Queue::Gearman::Select->new($self->all);
}

sub pick {
    my $self = shift;
    my @servers = @{ $self->servers };
    return $self->get($servers[int rand @servers]);
}

1;
__END__
