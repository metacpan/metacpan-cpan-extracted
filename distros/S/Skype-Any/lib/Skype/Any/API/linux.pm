package Skype::Any::API::linux;
use strict;
use warnings;
use parent qw/Skype::Any::API/;
use AnyEvent;
use AnyEvent::DBus;
use Net::DBus::Skype::API;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $client = Net::DBus::Skype::API->new(
        name     => $self->{skype}->{name},
        protocol => $self->{skype}->{protocol},
        notify   => $self->_notification_handler(),
    );
    $self->{client} = $client;

    $self->attach;

    return $self;
}

sub run { AE::cv()->recv }

sub attach {
    my $self = shift;
    if (!$self->{connected}) {
        $self->{client}->attach;
        $self->{connected} = 1;

        return 1;
    } else {
        return 0;
    }
}

sub is_running { $_[0]->{client}->is_running }
sub send       { shift->{client}->send_command(@_) }

1;
