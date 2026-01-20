#!/usr/bin/perl

use v5.26;
use warnings;


use Protocol::Sys::Virt::KeepAlive;
use Protocol::Sys::Virt::Transport;
use Protocol::Sys::Virt::Remote;


use JSON::PP;

my $json = JSON::PP->new->canonical;

sub on_ping {
}

sub on_pong {
}

sub dump_call {
    my %args = @_;
    my ($header, $data, $fds, $hole) = @args{ qw( header data fds hole ) };
    say $json->encode( [ header => $header, data => $data ] );
}

sub dump_reply {
    my %args = @_;
    my ($header, $data, $error, $fds, $hole) = @args{ qw( header data error fds hole ) };
    say $json->encode( [ header => $header, data => $data, error => $error ] );
}

sub dump_message {
    my %args = @_;
    my ($header, $data) = @args{ qw( header data ) };
    say $json->encode( [ header => $header, data => $data ] );
}

sub dump_stream {
    my %args = @_;
    my ($header, $fds, $data, $hole, $final, $eof) = @args{ qw( header fds data hole final eof ) };
    my $len = length $data;
    say $json->encode( [ header => $header, final => $final, data => "<data length: $len>", hole => $hole ] );
}

my $keepalive = Protocol::Sys::Virt::KeepAlive->new(
     on_ack => \&on_pong,
     on_ping => \&on_ping,
     on_fail => sub {}
);
my $transport = Protocol::Sys::Virt::Transport->new(
     role => 'server',
     on_send => sub { die 'Transport tries to send! Interpreting recorded stream. Sending not available.' }
);
my $remote = Protocol::Sys::Virt::Remote->new(
    role => 'server',
    on_call => \&dump_call,
    on_reply => \&dump_reply,
    on_message => \&dump_message,
    on_stream => \&dump_stream,
);

$keepalive->register( $transport );
$remote->register( $transport );

open my $fh, '<:raw', $ARGV[0]
  or die "Unable to open recorded session '$ARGV[0]': $!";

my $recording = do {
     local $/;
     <$fh>;
};

my $idx = 0;
my $len = length $recording;
while ($idx < $len) {
    my ($next) = $transport->need;
    my $chunk  = substr( $recording, $idx, $next );
    $idx += $next;

    print "$next: ";
    $transport->receive( $chunk );
}
$transport->receive( $recording );

