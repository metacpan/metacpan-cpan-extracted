package Skype::Any::API::darwin;
use strict;
use warnings;
use parent qw/Skype::Any::API/;
use Carp ();
use AnyEvent;
use Cocoa::Skype;
use Cocoa::EventLoop;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $name = $self->{skype}->{name};
    my $protocol = $self->{skype}->{protocol};

    my $client; $client = Cocoa::Skype->new(
        name => $name,
        on_attach_response => sub {
            my $code = shift;
            $self->{connected} = 1;
            if ($code == 1) { # on success
                $client->send("PROTOCOL $protocol");
            } else {
                Carp::croak("Can't connect Skype API client application (perhaps you forgot to start Skype.app, or allow '$name' to access Skype API)");
            }
        },
        on_notification_received => $self->_notification_handler(),
    );
    $self->{client} = $client;

    $self->attach;

    return $self;
}

sub run { Cocoa::EventLoop->run }

sub attach {
    my $self = shift;

    if (!$self->{connected}) {
        $self->{client}->connect;

        my $name = $self->{skype}->{name};
        my $timeout = AE::timer 60, 0, sub {
            Carp::croak("Can't connect Skype API client application. You have to allow '$name' to access Skype API");
        };
        while (!$self->{connected}) {
            Cocoa::EventLoop->run_while(0.01);
        }
        undef $timeout;

        return 1;
    } else {
        return 0;
    }
}

sub is_running { $_[0]->{client}->isRunning }
sub send       { shift->{client}->send(@_) }

# XXX OS X hack
# Why Cocoa::EventLoop doesn't support blocking wait? I asked to typester-san, he said "Cocoa sucks" :)

sub AnyEvent::Impl::Cocoa::_poll {
    # just affects performance
    Cocoa::EventLoop->run_while(0.01);
}

sub AnyEvent::Condbar::Base::_wait {
    Cocoa::EventLoop->run_while(0.01) until exists $_[0]{_ae_sent};
}

1;
