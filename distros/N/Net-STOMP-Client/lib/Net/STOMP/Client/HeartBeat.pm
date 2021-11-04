#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/HeartBeat.pm                                          #
#                                                                              #
# Description: Heart-beat support for Net::STOMP::Client                       #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::HeartBeat;
use strict;
use warnings;
our $VERSION  = "2.5";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.4 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use No::Worries::Die qw(dief);
use No::Worries::Export qw(export_control);
use Params::Validate qw(validate_pos :types);
use Time::HiRes qw();

#
# get/set the client heart-beat
#

sub client_heart_beat : method {
    my($self, $value);

    $self = shift(@_);
    return($self->{"client_heart_beat"}) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and defined($value) and ref($value) eq "") {
        $self->{"client_heart_beat"} = $value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, { optional => 1, type => SCALAR });
}

#
# get/set the server heart-beat
#

sub server_heart_beat : method {
    my($self, $value);

    $self = shift(@_);
    return($self->{"server_heart_beat"}) if @_ == 0;
    $value = $_[0];
    if (@_ == 1 and defined($value) and ref($value) eq "") {
        $self->{"server_heart_beat"} = $value;
        return($self);
    }
    # otherwise complain...
    validate_pos(@_, { optional => 1, type => SCALAR });
}

#
# get the last time we received/read data
#

sub last_received : method {
    my($self) = @_;

    return(undef) unless $self->{"io"};
    return($self->{"io"}{"incoming_time"});
}

#
# get the last time we sent/wrote data
#

sub last_sent : method {
    my($self) = @_;

    return(undef) unless $self->{"io"};
    return($self->{"io"}{"outgoing_time"});
}

#
# send a NOOP frame only if needed wrt heart-beat settings
#

sub beat : method {
    my($self, %option) = @_;
    my($delta, $sent);

    # check if client heart-beats are expected
    $delta = $self->client_heart_beat();
    return($self) unless $delta;
    # check the last time we sent data
    $sent = $self->last_sent();
    return($self) if Time::HiRes::time() - $sent < $delta / 2;
    # send a NOOP frame
    return($self->noop(%option));
}

#
# setup
#

sub _setup ($) {
    my($self) = @_;

    # additional options for new()
    return(
        "client_heart_beat" => { optional => 1, type => SCALAR },
        "server_heart_beat" => { optional => 1, type => SCALAR },
    ) unless $self;
}

#
# hook for the CONNECT frame
#

sub _connect_hook ($$) {
    my($self, $frame) = @_;
    my($chb, $shb);

    # do not override what the user did put in the frame
    return if defined($frame->header("heart-beat"));
    # do nothing when only STOMP 1.0 is asked
    return unless grep($_ ne "1.0", $self->accept_version());
    # add the appropriate header (in milliseconds!)
    $chb = int(($self->client_heart_beat() || 0) * 1000.0 + 0.5);
    $shb = int(($self->server_heart_beat() || 0) * 1000.0 + 0.5);
    $frame->header("heart-beat", "$chb,$shb") if $chb or $shb;
}

#
# negotiation helper
#

sub _maxif ($$) {
    my($x, $y) = @_;

    return(0) unless $x and $y;
    return($x > $y ? $x : $y);
}

#
# hook for the CONNECTED frame
#

sub _connected_hook ($$) {
    my($self, $frame) = @_;
    my($value, $shb, $chb);

    $value = $frame->header("heart-beat");
    if (defined($value)) {
        # given specification: check
        if ($value =~ /^(\d+),(\d+)$/) {
            ($shb, $chb) = ($1 / 1000.0, $2 / 1000.0);
            $self->server_heart_beat(_maxif($self->server_heart_beat(), $shb));
            $self->client_heart_beat(_maxif($self->client_heart_beat(), $chb));
        } else {
            dief("unexpected heart-beat specification: %s", $value);
        }
    } else {
        # missing specification: disable
        $self->client_heart_beat(0);
        $self->server_heart_beat(0);
    }
}

#
# register the setup and hooks
#

{
    no warnings qw(once);
    $Net::STOMP::Client::Setup{"heart-beat"} = \&_setup;
    $Net::STOMP::Client::Hook{"CONNECT"}{"heart-beat"} = \&_connect_hook;
    $Net::STOMP::Client::Hook{"CONNECTED"}{"heart-beat"} = \&_connected_hook;
}

#
# export control
#

sub import : method {
    my($pkg, %exported);

    $pkg = shift(@_);
    grep($exported{$_}++, qw(beat));
    grep($exported{$_}++, map("${_}_heart_beat", qw(client server)));
    grep($exported{$_}++, map("last_${_}", qw(received sent)));
    export_control(scalar(caller()), $pkg, \%exported, @_);
}

1;

__END__

=head1 NAME

Net::STOMP::Client::HeartBeat - Heart-beat support for Net::STOMP::Client

=head1 SYNOPSIS

  use Net::STOMP::Client;
  $stomp = Net::STOMP::Client->new(host => "127.0.0.1", port => 61613);
  ...
  # can set the desired configuration only _before_ connect()
  # the client can send heart-beats every 5 seconds
  $stomp->client_heart_beat(5);
  # the server should send heart-beats every 10 seconds
  $stomp->server_heart_beat(10);
  ...
  $stomp->connect();
  ...
  # can get the negotiated configuration only _after_ connect()
  printf("negotiated heart-beats: client=%.3f server=%.3f\n",
      $stomp->client_heart_beat(), $stomp->server_heart_beat());

=head1 DESCRIPTION

This module handles STOMP heart-beat negotiation. It is used internally by
L<Net::STOMP::Client> and should not be directly used elsewhere.

=head1 METHODS

This module provides the following methods to L<Net::STOMP::Client>:

=over

=item client_heart_beat([VALUE])

get/set the client heart-beat

=item server_heart_beat([VALUE])

get/set the server heart-beat

=item last_received()

get the time at which data was last received, i.e. read from the network socket

=item last_sent()

get the time at which data was last sent, i.e. written to the network socket

=item beat([OPTIONS])

send a NOOP frame (using the noop() method) unless the last sent time is
recent enough with regard to the client heart-beat settings

=back

For consistency with other Perl modules (for instance L<Time::HiRes>), time
is always expressed as a fractional number of seconds.

=head1 HEART-BEATING

Starting with STOMP 1.1, each end of a STOMP connection can check if the
other end is alive via heart-beating.

In order to use heart-beating (which is disabled by default), the client
must specify what it wants before sending the C<CONNECT> frame. This can be
done using the C<client_heart_beat> and C<server_heart_beat> options of the
new() method or, this is equivalent, the client_heart_beat() and
server_heart_beat() methods on the L<Net::STOMP::Client> object.

After having received the C<CONNECTED> frame, the client_heart_beat() and
server_heart_beat() methods can be used to get the negotiated values.

To prove that it is alive, the client just needs to call the beat() method
when convenient.

To check if the server is alive, the client just needs to compare the
current time and what is returned by the last_received() and
server_heart_beat() methods. For instance:

  $delta = $stomp->server_heart_beat();
  if ($delta) {
      $inactivity = Time::HiRes::time() - $stomp->last_received();
      printf("server looks dead!\n") if $inactivity > $delta;
  }

=head1 SEE ALSO

L<Net::STOMP::Client>,
L<Time::HiRes>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2021
