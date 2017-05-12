package Speechd;
use 5.006;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.50';

use IO::Socket::INET;


=pod

=head1 NAME

Speechd - Perl Module wrapper for speech-dispatcher.

=head1 DESCRIPTION

Speechd is a Perl module to make it easy to use speech-dispatcher
for text to speech functions.

=head1 SYNOPSIS

my $sd = Speachd->new([property => value, property => value, ...]);

=head2 PROPERTIES

=over 4

=item port : Port number.  

Default is 6560

=item ip : IP address. 

Default is 127.0.0.1

=item voice : Voice name. 

Default is MALE1. 
Possible voice names are:
MALE1 MALE2 MALE3 FEMALE1 FEMALE2 FEMALE3 CHILD_MALE CHILD_FEMALE

=item rate : Speaking rate. 

Default is 0. 
Possible values are from -100 to 100.

=item volume : Speaking volume. 

Default is 0. 
Possible values are from -100 to 100.

=item pitch : Speaking pitch. 

Default is 0. 
Possible values are from -100 to 100.

=item lang : Speaking lanuage. 

Default value is en (english). 

=back

=head2 METHODS

=over 4

=item new

my $sd = Speachd->new([property => value, property => value, ...]);

Creates a new instance of the Speachd object.

=cut

sub new {
	my $pkg = shift;
	my $self = {
		"port" => 6560,
		"ip" => "127.0.0.1",
                "voice" => "MALE1",
                "rate" => 0,
                "volume" => 0,
                "pitch" => 0,
                "lang" => "en",
		@_};
	return bless $self, $pkg;
}

=pod

=item connect

$sd->connect();

Connect a socket to speech-dispatcher. 
This must be called before methods say, cancel, voice,
volume, pitch, lang, and config_voice can be used.

=cut
sub connect {
    my $self = shift;
    $self->{socket} = IO::Socket::INET->new(
				PeerAddr => $self->{ip},
                                PeerPort => $self->{port},
                                Proto    => "tcp",
                                Type     => SOCK_STREAM,
                                Blocking => 0,
    ) or die "
    Couldn't connect to speechd on port $self->{'port'} and IP $self->{'ip'}: 
    $@\n
    Perhaps speech-dispatcher is not running.";
}
=pod

=item disconnect

$sd->disconnect();

Disconnect socket from speech-dispatcher. 

=cut
sub disconnect {
    my $self = shift;
    $self->sendraw("quit\r\n");
    $self->{socket}->close();
}

=pod

=item port

$sd->port([$port_number]);

If port number is given; sets port number and returns previos value.
If no port number is given; returns value.
Default value is 6560

=cut 
sub port {
    my $self = shift;
    my $port = shift;
    my $ret = $self->{'port'};
    if ($port) {
	$self->{'port'} = $port;
    }
    return $ret;
}

=pod

=item ip

$sd->ip([$ip_address]);

If ip address is given; sets ip address and returns previos value.
If no ip address is given; returns value.
Default value is 127.0.0.1

=cut 
sub ip {
    my $self = shift;
    my $ip = shift;
    my $ret = $self->{ip};
    if ($ip) {
	$self->{ip} = $ip;
    }
    return $ret;
}

=pod

=item voice

$sd->voice([$voice]);

If voice is given; sets voice and returns previos value.
If no voice is given; returns value.
Default value is MALE1. Possible values are:
MALE1 MALE2 MALE3 FEMALE1 FEMALE2 FEMALE3 CHILD_MALE CHILD_FEMALE
If not connected, method msg will return error.

=cut 
sub voice {
    my $self = shift;
    my $voice = shift;
    my $ret = $self->{voice};
    if ($voice) {
	$self->{voice} = $voice;
        $self->sendraw("set self voice $voice\r\n");
    }
    return $ret;
}

=pod

=item rate

$sd->rate([$rate]);

If rate is given; sets rate and returns previos value.
If no rate is given; returns value.
Default value is 0. Possible values are from -100 to 100.
If not connected, method msg will return error.

=cut 
sub rate {
    my $self = shift;
    my $rate = shift;
    my $ret = $self->{rate};
    if ($rate) {
	$self->{rate} = $rate;
        $self->sendraw("set self rate $rate\r\n");
    }
    return $ret;
}

=pod

=item volume

$sd->volume([$volume]);

If volume is given; sets volume and returns previos value.
If no volume is given; returns value.
Default value is 0. Possible values are from -100 to 100.
If not connected, method msg will return error.

=cut 
sub volume {
    my $self = shift;
    my $volume = shift;
    my $ret = $self->{volume};
    if ($volume) {
	$self->{volume} = $volume;
        $self->sendraw("set self volume $volume\r\n");
    }
    return $ret;
}

=pod

=item pitch

$sd->pitch([$pitch]);

If volume is given; sets volume and returns previos value.
If no volume is given; returns value.
Default value is 0. Possible values are from -100 to 100.
If not connected, method msg will return error.

=cut 
sub pitch {
    my $self = shift;
    my $pitch = shift;
    my $ret = $self->{pitch};
    if ($pitch) {
	$self->{pitch} = $pitch;
        $self->sendraw("set self pitch $pitch\r\n");
    }
    return $ret;
}

=pod

=item lang

$sd->lang([$lang]);

If lang is given; sets language and returns previos value.
If no lang is given; returns value.
Default value is en.
If not connected, method msg will return error.

=cut 
sub lang {
    my $self = shift;
    my $lang = shift;
    my $ret = $self->{lang};
    if ($lang) {
	$self->{lang} = $lang;
        $self->sendraw("set self language $lang\r\n");
    }
    return $ret;
}

=pod

=item config_voice

$sd->config_voice($voice, $lang, [$rate, $volume, $pitch]);

Sets parameters for speech-dispatcher. 
See individual methods for possible values.

=cut 
sub config_voice { # voice, lang, rate, volume, pitch
    my $self = shift;
    my $voice = shift;
    my $lang = shift;
    my $rate = shift;
    my $vol = shift;
    my $pitch = shift;
    $self->voice($voice);
    $self->rate($rate);
    $self->volume($vol);
    $self->pitch($pitch);
    $self->lang($lang);
}

=pod

=item msg

my $message = $sd->msg();

Returns and clears messages from previous command sent to speechd.

=cut
sub msg {
    my $self = shift;
    my $msg = $self->{msg};
    $self->{msg} = "";
    return $msg;
}


=pod

=item say

$sd->say($text_to_speak);

Sends text to speech-dispatcher to be spoken.

=cut
sub say {
    my $self = shift;
    my $text = shift;
    $self->sendraw("speak\r\n$text\r\n.\r\n");
}

=pod

=item cancel

$sd->cancel();

Kills speech.

=cut
sub cancel {
    my $self = shift;
    $self->sendraw("cancel self\r\n");
}

=pod

=item get_voices

my $voices = $sd->get_voices();

Returns a reference to an array holding all possible voice names.

=cut
sub get_voices {
    my $self = shift;
    my @voice_lst = qw(MALE1 MALE2 MALE3 FEMALE1 FEMALE2 FEMALE3 CHILD_MALE CHILD_FEMALE);
    return \@voice_lst;
}

=pod

=item sendraw

$sd->sendraw($command_to_send_to_speech-dispatcher);

Available to send commands directly to speech-dispatcher.
Puts return messages into msg.

=back

=cut
sub sendraw {
    my $self = shift;
    my $raw = shift;
    if ($self->{socket}->connected()) {
        $self->msg();
	$self->{socket}->print($raw);
	while (my $ln = $self->{socket}->getline()) {
	    $self->{msg} .= $ln;
	}
    } else {
	$self->{msg} = "Error no socket connection.\n";
	print $self->{msg};
    }
}


1;

__END__

=head1 EXAMPLE

 #!/usr/bin/perl

 use strict;
 use warnings;

 use Speechd;

 my $rate = 0;
 my $vol = 0;
 my $pitch = 0;
 my $lang = "en";
 my $voice = "MALE1";

 my $sd = Speechd->new(
    'rate' => $rate,
    'volume' => $vol,
    'lang' => $lang,
    'voice' => $voice,
 );

 $sd->connect();

 while (1) {
    print "Enter text to speak:\n";
    my $text = <>;
    $sd->say($text);
    my $message = $sd->msg();
    print $message;
    chomp $text;
    $text = lc($text);
    last if $text eq "goodbye";
 }

 $sd->disconnect();

 exit 0;

=head1 SEE ALSO

More information about speech-dispatcher can be fount at:
http://www.freebsoft.org

=head1 AUTHOR

Joe Kamphaus, E<lt>joe@joekamphaus.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Joe Kamphaus

 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; version 2 of the License or any later version.

 This module is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.


=cut
