package Net::YahooMessenger::Buddy;
use strict;

use constant IM_AVAILABLE      => 0;
use constant BE_RIGHT_BACK     => 1;
use constant BUSY              => 2;
use constant NOT_AT_HOME       => 3;
use constant NOT_AT_MY_DESK    => 4;
use constant NOT_IN_THE_OFFICE => 5;
use constant ON_THE_PHONE      => 6;
use constant ON_VACATION       => 7;
use constant OUT_TO_LUNCH      => 8;
use constant STEPPED_OUT       => 9;
use constant CUSTOM_STATUS     => 99;
use constant SLEEP             => 999;

use constant ICON_AVAILABLE => 0;
use constant ICON_BUSY      => 1;
use constant ICON_SLEEP     => 2;

use constant STATUS_MESSAGE => [
    "I'm Available",
    'Be Right Back',
    'Busy',
    'Not At Home',
    'Not At My Desk',
    'Not In The Office',
    'On The Phone',
    'On Vacation',
    'Out To Lunch',
    'Stepped Out',
];

use constant IS_ONLINE  => 1;
use constant IS_OFFLINE => 0;

sub new {
    my $class = shift;
    bless {
        name          => 'nobody',
        status        => IM_AVAILABLE,
        custom_status => '',
        busy          => ICON_AVAILABLE,
        online        => IS_OFFLINE,
        session_id    => 0,
    }, $class;
}

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    $self->{name};
}

sub status {
    my $self = shift;
    if (@_) {
        $self->{status} = shift;
        $self->busy(ICON_BUSY)  if $self->{status} <= STEPPED_OUT;
        $self->busy(ICON_SLEEP) if $self->{status} == SLEEP;
        $self->busy(ICON_AVAILABLE)
          if $self->{status} == CUSTOM_STATUS
              || $self->{status} == IM_AVAILABLE;
    }
    $self->{status};
}

sub custom_status {
    my $self = shift;
    if (@_) {
        $self->{custom_status} = shift;
        $self->status(CUSTOM_STATUS);
    }
    $self->{custom_status};
}

sub busy {
    my $self = shift;
    if (@_) {
        $self->{busy} = shift;
    }
    $self->{busy};
}

sub online {
    my $self = shift;
    if (@_) {
        $self->{online} = shift;
    }
    $self->{online};
}

sub session_id {
    my $self = shift;
    $self->{session_id} = shift if @_;
    $self->{session_id};
}

sub is_online {
    my $self = shift;
    $self->online;
}

sub get_status_message {
    my $self = shift;
    return unless $self->is_online;

    if ( $self->status == SLEEP ) {
        return sprintf '%s', 'Sleep';
    }
    elsif ( $self->status == CUSTOM_STATUS ) {
        return sprintf '%s', $self->custom_status;
    }
    elsif ( $self->status >= IM_AVAILABLE && $self->status <= STEPPED_OUT ) {
        return sprintf '%s', STATUS_MESSAGE->[ $self->status ];
    }
    else {
        return 'Unknown';
    }
}

sub to_string {
    my $self = shift;
    if ( $self->is_online ) {
        return
          sprintf "%s %s (%s)",
          $self->busy == ICON_AVAILABLE ? ':-)'
          : $self->busy == ICON_BUSY    ? ':-@'
          : $self->busy == ICON_SLEEP   ? '|-I'
          : '?',
          $self->name,
          $self->get_status_message;
    }
    else {
        return sprintf "%s %s (%s)", '   ', $self->name, 'Not online';
    }
}

1;
__END__
