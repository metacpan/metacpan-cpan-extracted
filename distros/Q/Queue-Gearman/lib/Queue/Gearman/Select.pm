package Queue::Gearman::Select;
use strict;
use warnings;
use utf8;

use IO::Select;

sub new {
    my $class = shift;
    my $self  = bless +{
        owner_pid => $$,
        select    => IO::Select->new,
        socket    => {},
    } => $class;
    $self->add(@_);
    return $self;
}

sub sockets {                  values %{ shift->{socket} } }
sub socks   { map { $_->sock } values %{ shift->{socket} } }

sub select :method {
    my $self = shift;
    delete $self->{select} if exists $self->{owner_pid} && $self->{owner_pid} != $$;
    return $self->{select} if exists $self->{select};

    $self->{owner_pid} = $$;
    return $self->{select} = IO::Select->new($self->socks);
}

sub add {
    my $self = shift;

    my $select = $self->select();
    for my $socket (@_) {
        $self->{socket}->{$socket->sock->fileno} = $socket;
        $select->add($socket->sock);
    }
}

sub remove {
    my $self = shift;

    my $select = $self->select();
    for my $socket (@_) {
        delete $self->{socket}->{$socket->sock->fileno};
        $select->remove($socket->sock);
    }
}

sub can_read {
    my $self = shift;
    my @ready = $self->select()->can_read(@_);
    return @{$self->{socket}}{map { $_->fileno } @ready};
}

sub can_write {
    my $self = shift;
    my @ready = $self->select()->can_read(@_);
    return @{$self->{socket}}{map { $_->fileno } @ready};
}

1;
__END__
