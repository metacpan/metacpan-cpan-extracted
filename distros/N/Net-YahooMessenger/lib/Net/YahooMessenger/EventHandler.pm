package Net::YahooMessenger::EventHandler;
use strict;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub accept {
    my $self  = shift;
    my $event = shift;

    my $method = ref $event;
    $method =~ s/^.*://;
    $self->$method($event);
}

sub Login {
    my $self = shift;
}

sub InvalidLogin {
    my $self = shift;
}

sub ReceiveMessage {
    my $self = shift;
}

sub GoesOnline {
    my $self = shift;

}

sub GoesOffline {
    my $self = shift;
}

sub ChangeState {
    my $self = shift;
}

sub NewFriendAlert {
    my $self = shift;
}

sub NullEvent {
    my $self = shift;
}

sub UnImplementEvent {
    my $self = shift;

}

1;
__END__
