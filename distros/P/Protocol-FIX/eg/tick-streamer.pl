#!/usr/bin/env perl

=head1 NAME

tick-streamer - Mojolicious-based FIX-server

=head1 SYNOPSIS

perl tick-streamer.pl [options]

 Options
  -p, --listening_port          Port, on which server will accept incoming connections
  -s, --symbol_list             Comma-separated symbols list (e.g. EURCAD, EURUSD)
  -S, --SenderCompID            SenderCompID (e.g. FixServer)
  -T, --TargetCompID            TargetCompID (e.g. Client1)
  -U, --Username                Username
  -P, --Password                Password (hmac sha 256 of username and password)
  -l, --log                     Log level
  -h, --help                    Show this message.

=head1 DESCRIPTION

Mojolicious-based FIX-server which streams quotes with randomly generated prices

=cut

use strict;
use warnings;

use Mojo::IOLoop::Server;
use Mojo::IOLoop;
use Protocol::FIX qw/humanize/;
use POSIX qw(strftime);
use Digest::SHA qw(hmac_sha256_hex);
use Pod::Usage;
use Getopt::Long qw(GetOptions :config no_auto_abbrev no_ignore_case);

use Log::Any qw($log);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

require Log::Any::Adapter;
GetOptions(
    'p|listening_port=i' => \my $port,
    's|symbol_list=s'    => \my $symbol_list,
    'S|SenderCompID=s'   => \my $sender_comp_id,
    'T|TargetCompID=s'   => \my $target_comp_id,
    'U|Username=s'       => \my $username,
    'P|Password=s'       => \my $password,
    'l|log=s'            => \my $log_level,
    'h|help'             => \my $help,
    )
    or pod2usage({
        -verbose  => 99,
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS",
    });

Log::Any::Adapter->set(qw(Stdout), log_level => $log_level // 'info');

my $show_help =
       $help
    || !$port
    || !$symbol_list
    || !$sender_comp_id
    || !$target_comp_id
    || !$username
    || !$password;

pod2usage({
        -verbose  => 99,
        -sections => "NAME|SYNOPSIS|DESCRIPTION|OPTIONS",
    }) if $show_help;

Log::Any::Adapter->set(qw(Stdout), log_level => $log_level // 'info');

my @symbols = sort split /,/, $symbol_list;
my %price_for = map {
    my $s     = $_;
    my $price = sprintf('%0.3f', 1000 * rand);
    $log->debugf("initial price for %s = %s", $s, $price);
    $s => $price;
} @symbols;

my $send_quotes;

my $send_message = sub {
    my ($client, $message) = @_;
    $log->debugf("=> %s : %s", $client->{id}, ($message =~ s/\x{01}/|/gr));
    $client->{stream}->write($message);
};

Mojo::IOLoop->recurring(
    1 => sub {
        $log->debug("refreshing quotes");
        for my $symbol (@symbols) {
            my $price = $price_for{$symbol};
            my $delta = $price * 0.0001;
            $price += (rand() * $delta) - $delta * 0.5;
            $price = sprintf('%0.3f', $price);
            $log->debugf("%s => %s", $symbol, $price);
            $price_for{$symbol} = $price;
        }
        $send_quotes->();
    });

my %session_for;
my $fix_protocol = Protocol::FIX->new('FIX44');

$send_quotes = sub {
    for my $client (grep { $_->{status} eq 'authorized' } values %session_for) {
        for my $symbol (@symbols) {
            my $price     = $price_for{$symbol};
            my $timestamp = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
            my $message   = $fix_protocol->message_by_name('MarketDataSnapshotFullRefresh')->serialize([
                    SenderCompID => $sender_comp_id,
                    TargetCompID => $target_comp_id,
                    MsgSeqNum    => $client->{msg_seq}++,
                    SendingTime  => $timestamp,
                    Instrument   => [Symbol => $symbol],
                    MDFullGrp    => [
                        NoMDEntries => [[
                                MDEntryType => 'BID',
                                MDEntryPx   => $price
                            ],
                            [
                                MDEntryType => 'OFFER',
                                MDEntryPx   => $price
                            ],
                        ]
                    ],
                ]);
            $send_message->($client, $message);
        }
        $log->debugf("%s has been sent to %s", scalar(@symbols), $client->{id});
    }
};

my $on_Logon = sub {
    my ($client, $message) = @_;
    if ($client->{status} eq 'unauthorized') {
        my $ok         = 1;
        my $error_code = '';
        $ok &&= ($message->value('SenderCompID') eq $target_comp_id) || do {
            $error_code = 'SenderCompID_Mismatch';
            $log->debugf("SenderCompID mismatch: %s vs %s", $message->value('SenderCompID'), $target_comp_id);
            0;
        };
        $ok &&= ($message->value('TargetCompID') eq $sender_comp_id) || do {
            $error_code = 'TargetCompID_Mismatch';
            $log->debugf("TargetCompID mismatch: %s vs %s", $message->value('TargetCompID'), $sender_comp_id);
            0;
        };
        $ok &&= ($message->value('Username') eq $username) || do {
            $error_code = 'Credentials_Mismatch';
            $log->debugf("Username mismatch: %s vs %s", $message->value('Username'), $username);
            0;
        };
        $ok &&= ($message->value('Password') eq hmac_sha256_hex($username, $password)) || do {
            $error_code = 'Credentials_Mismatch';
            $log->debugf("Password mismatch: %s vs %s", $message->value('Password'), $password);
            0;
        };
        if ($ok) {
            $log->debugf("authorizing %s", $client->{id});
            $client->{status} = 'authorized';

            my $timestamp = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
            my $message   = $fix_protocol->message_by_name('Logon')->serialize([
                SenderCompID  => $sender_comp_id,
                TargetCompID  => $target_comp_id,
                MsgSeqNum     => $client->{msg_seq}++,
                SendingTime   => $timestamp,
                EncryptMethod => 'NONE',
                HeartBtInt    => 60,
            ]);

            $send_message->($client, $message);
        } else {
            $log->debugf("credentials mismatch %s", $client->{id});

            my $timestamp = strftime("%Y%m%d-%H:%M:%S.000", gmtime);
            my $message   = $fix_protocol->message_by_name('Logout')->serialize([
                SenderCompID => $sender_comp_id,
                TargetCompID => $target_comp_id,
                SendingTime  => $timestamp,
                MsgSeqNum    => $client->{msg_seq}++,
                Text         => "Invalid login. Error: $error_code."
            ]);

            $send_message->($client, $message);
        }
    } else {
        $log->debug("client is already authorized, protocol error");
    }
};

my %dispatcher = (
    Logon => $on_Logon,
);

my $on_accept = sub {
    my $client = shift;
    my $stream = $client->{stream};
    $stream->on(
        read => sub {
            my ($stream, $bytes) = @_;
            $client->{buff} .= $bytes;
            $log->debugf("Received %s bytes from client %s", length($bytes), $client->{id});
            $log->debugf(humanize($bytes), "\n");

            my ($message, $err) = $fix_protocol->parse_message(\$client->{buff});
            if ($err) {
                $log->debugf("Got protocol error from %s, error %s", $client->{id}, $err);
            } elsif ($message) {
                my $name = $message->name;
                $log->debugf("Message %s", $name);
                my $handler = $dispatcher{$name} // die("No handler for message '$name'");
                $handler->($client, $message);
            } else {
                $log->debug("Not enough data to parse message");
            }
        });
    $stream->on(
        close => sub {
            my $stream = shift;
            $log->debugf("Stream for client %s has been closed", $client->{id});
            delete $session_for{$client->{id}};
        });
    $stream->on(
        error => sub {
            my ($stream, $err) = @_;
            $log->debugf("Client %s errored with %s", $client->{id}, $err);
        });
    $stream->start;
};

my $server = Mojo::IOLoop::Server->new;
$server->on(
    accept => sub {
        my ($server, $handle) = @_;
        my $client_id = $handle->peerhost . ":" . $handle->peerport;
        $log->debugf("accepted client: %s", $client_id);
        my $stream = Mojo::IOLoop::Stream->new($handle);
        my $client = {
            id      => $client_id,
            stream  => $stream,
            status  => 'unauthorized',
            buff    => '',
            msg_seq => 1,
        };
        $session_for{$client_id} = $client;
        $on_accept->($client);
    });
$server->listen(port => $port);

$server->start;

# Start reactor if necessary
$server->reactor->start unless $server->reactor->is_running;
