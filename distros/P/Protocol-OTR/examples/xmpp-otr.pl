#!/usr/bin/env perl

# most of the code is taken from AnyEvent::XMPP's samples/talkbot

use strict;
use utf8;
use AnyEvent;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Namespaces qw/xmpp_ns/;

BEGIN { $ENV{PROTOCOL_OTR_ENABLE_QUICK_RANDOM} = 1 }

use Protocol::OTR;

binmode STDOUT, ":utf8";

my ( $jid, $pw ) = @ARGV;

unless ( @ARGV >= 2 ) {
    warn "Usage: $0 <jid> <password>\n";
    exit;
}

my $j       = AnyEvent->condvar;
my $cl      = AnyEvent::XMPP::Client->new( debug => 1 );
my $disco   = AnyEvent::XMPP::Ext::Disco->new;
my $version = AnyEvent::XMPP::Ext::Version->new;

my $otr = Protocol::OTR->new();

my $act = $otr->account( $jid, 'prpl-jabber' );

my %cnts;

$cl->add_extension($disco);
$cl->add_extension($version);

$cl->set_presence( undef, 'I\'m a talking OTR bot.', 1 );

$cl->add_account( $jid, $pw );
warn "connecting to $jid...\n";

$cl->reg_cb(
    session_ready => sub {
        my ( $cl, $acc ) = @_;
        warn "connected!\n";
    },
    message => sub {
        my ( $cl, $acc, $msg ) = @_;

        my $from    = $msg->from;
        my $msgin = $msg->any_body;

        unless ( exists $cnts{$from} ) {
            $cnts{$from} = { cnt => $act->contact($from) };
            $cnts{$from}->{channel} = $cnts{$from}->{cnt}->channel(
                {
                    on_read => sub {
                        my ($c, $message) = @_;

                        my $msgout = "You said '" . $message . "' but... " . uc $message;

                        warn "Response set to: $msgout\n";

                        $c->write( $msgout );
                    },
                    on_write => sub {
                        my ($c, $message) = @_;

                        my $repl = $msg->make_reply;
                        $repl->add_body( $message );
                        $repl->send;

                        warn "Encrypted message sent\n";
                    },
                    on_is_contact_logged_in => sub { 1 },
                    on_smp => sub {
                        my ($c, $q) = @_;

                        $c->smp_respond(scalar reverse $q);

                        warn "SMP response sent\n";
                    }
                }
            );
        }

        $cnts{$from}->{channel}->read($msgin);
    },
    contact_request_subscribe => sub {
        my ( $cl, $acc, $roster, $contact ) = @_;
        $contact->send_subscribed;
        warn "Subscribed to " . $contact->jid . "\n";
    },
    error => sub {
        my ( $cl, $acc, $error ) = @_;
        warn "Error encountered: " . $error->string . "\n";
        $j->broadcast;
    },
    disconnect => sub {
        warn "Got disconnected: [@_]\n";
        $j->broadcast;
    },
);

$cl->start;

$j->wait;

