#!/usr/bin/env perl

#----------------------------------------------------------------------
# No guarantees are made as to the robustness of this server code;
# this is meant purely as a demonstration of something cool to do with
# WebSocket. :)
#----------------------------------------------------------------------

use strict;
use warnings;
use autodie;

use Try::Tiny;

use Socket;

use IO::Events ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use lib "$FindBin::Bin/lib";
use MockReader ();
use NWDemo ();

use Text::Control ();

use Net::WebSocket::Endpoint::Server ();
use Net::WebSocket::Frame::text ();
use Net::WebSocket::Frame::binary ();
use Net::WebSocket::Frame::continuation ();
use Net::WebSocket::Parser ();

use constant {
    SEND_FRAME_CLASS => 'Net::WebSocket::Frame::binary',
};

use IO::Pty ();

#for setsid()
use POSIX ();

my $host_port = $ARGV[0] || die "Need host:port or port!\n";

if (index($host_port, ':') == -1) {
    substr( $host_port, 0, 0 ) = '127.0.0.1:';
}

my ($host, $port) = split m<:>, $host_port;

#my $loop = IO::Events::Loop->new( debug => 1 );
my $loop = IO::Events::Loop->new();

my %sessions;

sub _kill_session {
    my ($session) = @_;

    if ( $sessions{$session} ) {
        $sessions{$session}{'timeout'}->stop();

        $sessions{$session}{'client'}->destroy();

        if ($sessions{$session}{'shell'}) {
            $sessions{$session}{'shell'}->destroy();
        }

        delete $sessions{$session};
    }
}

my $read_obj = MockReader->new();

my $server = IO::Events::Socket::TCP->new(
    owner => $loop,
    listen => 1,
    addr => $host,
    port => $port,
    on_read => sub {
        my $shell = (getpwuid $>)[8] or die "No shell!";

        my $session = rand;

        my $did_handshake;

        my $ept;

        my $shell_hdl;

        my $client_hdl;

        my $cpid;

        my $timeout = IO::Events::Timer->new(
            owner => $loop,
            timeout => 5,
            repetitive => 1,
            active => 1,
            on_tick => sub {
                if ($did_handshake) {
                    $ept->check_heartbeat();

                    if ($ept->is_closed()) {
                        $shell_hdl->destroy();  #kills PID and $client_hdl
                    }
                }
                else {
                    _kill_session($session);
                }
            },
        );

        my $deflate;

        $client_hdl = shift()->accept(
            owner => $loop,
            read => 1,
            write => 1,
            on_close => sub {
                _kill_session($session);
            },
            on_read => sub {
                my ($client_hdl) = @_;

                $read_obj->add( $client_hdl->read() );

                if ($did_handshake) {

                    #There could be multiple WebSocket messages
                    #in the same TCP packet.
                    while (my $msg = $ept->get_next_message()) {

                        #printf STDERR "from client: %s\n", ($msg->get_payload() =~ s<([\x80-\xff])><sprintf '\x%02x', ord $1>gre);
                        #printf STDERR ">>>>> from browser: %d bytes\n", length $msg->get_payload();
                        #printf STDERR ">>>>> from browser: %v.02x\n", $msg->get_payload();
                        #print STDERR _printable( $msg->get_payload() ) . $/;

                        my $payload = $msg->get_payload();

                        if ($deflate && $deflate->message_is_compressed($msg)) {
                            $payload = $deflate->decompress($payload);
                        }

                        $shell_hdl->write( $payload );
                    }
                }
                else {
                    $ept ||= Net::WebSocket::Endpoint::Server->new(
                        parser => Net::WebSocket::Parser->new($read_obj),

                        #$client_hdl implements a compatible write() method.
                        out => $client_hdl,
                    );

                    (undef, my $hsk, $deflate) = NWDemo::get_server_handshake_from_text($read_obj->get());
                    return if !$hsk;

                    #Clear out $read_obj’s buffer.
                    $read_obj->read( length $read_obj->get() );

                    #----------------------------------------------------------------------

                    $client_hdl->write( $hsk->to_string() );
                    $did_handshake = 1;

                    my $pty = IO::Pty->new();

                    #Ideally this would happen; however, since this
                    #is being used to test zmodem.js let’s leave it out
                    #to imitate a likely omission from other shell servers.
                    #We will thus block any 0x0f and 0x16 bytes from reaching
                    #the shell.
                    #print IO::Stty::stty($pty, '-iexten');

                    $cpid = fork or do {
                        eval {
                            my $slv = $pty->slave();

                            open \*STDIN, '<&=', $slv;
                            open \*STDOUT, '>&=', $slv;
                            open \*STDERR, '>&=', $slv;

                            #Necessary for CTRL-C and CTRL-\ to work.
                            POSIX::setsid();

                            #Any advantage to this??
                            #setpgrp;

                            $pty->make_slave_controlling_terminal();

                            #Not all shells (e.g., tcsh) have “--login”.
                            exec { $shell } $shell, '-l' or die $!;
                        };
                        warn if $@;
                        POSIX::exit(1);
                    };

                    $shell_hdl = IO::Events::Handle->new(
                        owner => $loop,
                        handle => $pty,
                        read => 1,
                        write => 1,

                        #Anything we get from the shell we pass on to the
                        #(WebSocket) client.
                        on_read => sub {
                            my ($self) = @_;

                            my $frame_or_msg;

                            if ($deflate) {
                                $frame_or_msg = $deflate->create_message(
                                    SEND_FRAME_CLASS(),
                                    $self->read(),
                                );
                            }
                            else {

                                #Needs to be binary in case of ZMODEM transfer.
                                $frame_or_msg = SEND_FRAME_CLASS()->new(
                                    payload => $self->read(),
                                );
                            }

                            #printf STDERR "to client: %s\n", ($frame->to_bytes() =~ s<([\x80-\xff])><sprintf '\x%02x', ord $1>gre);
                            #printf STDERR "<<<<< to client: %v.02x\n", $frame->get_payload();
                            #printf STDERR "<<<<< to client: %d\n", length $frame->get_payload();
                            #print STDERR _printable( $frame->get_payload() ) . $/;

                            $client_hdl->write($frame_or_msg->to_bytes());
                        },

                        pid => $cpid,

                        on_close => sub {
                            _kill_session($session);
                        },
                    );

                    $sessions{$session}{'shell'} = $shell_hdl;
                }
            }
        );

        $sessions{$session} = {
            client => $client_hdl,
            timeout => $timeout,
        };
    },
);

#*_printable = \&Text::Control::to_dot;

while (1) {
    try {
        $loop->yield() while 1;
    }
    catch {

        #For this application the ReceivedClose exception is more useful
        #than the non-exception behavior.
        if ( !try { $_->isa('Net::WebSocket::X::ReceivedClose') } ) {
            local $@ = $_;
            die;
        }

        $loop->flush();
    };
}
