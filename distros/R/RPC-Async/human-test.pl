#!/usr/bin/env perl
use strict;
use warnings;

use RPC::Async::Client;
use IO::EventMux;
use Data::Dumper;

if (@ARGV < 1) {
    die "Usage: $0 SERVER-SCRIPT [ SERVER-ARGUMENTS ]\n";
}
my ($server, @server_args) = @ARGV;

my $mux = IO::EventMux->new();
$mux->add(\*STDIN, Buffered => ['Split', qr/\n/]);

my $rpc = RPC::Async::Client->new($mux, $server, @server_args) or die;

my $stdin_open = 1;

while ($stdin_open or $rpc->has_requests) {
    my $event = $rpc->io($mux->mux) or next;
    my $type = $event->{type};

    if ($type eq "closed") {
        $stdin_open = 0;

    } elsif ($type eq "read") {
        my $line = $event->{data};

        my ($proc, @args);
        if ($line =~ /^(\w+)\s+(.*)$/) {
            $proc = $1;
            my @pairs = split /\s+/, $2;

            @args = eval {
                map { /^([^=]+)\s*=\s*(.*)$/ ? ($1, $2) : die } @pairs
            };
            if ($@) {
                print "Invalid args.\n";
                next;
            }

        } elsif ($line =~ /^(\w+)\s*$/x) {
            $proc = $1;

        } else {
            print "Invalid line: '$line'\n";
            next;
        }

        $rpc->call($proc, @args, sub {
                my @reply = @_;
                print "    $proc(", format_args(@args), ")\n";
                print " -> ", format_args(@reply), "\n";
            });
    }
}

$rpc->disconnect;

sub format_args {
    my $str = "";
    for (my $i = 0; $i < @_; $i += 2) {
        my $value = $_[$i+1];
        if (ref $value) {
            $value = Dumper($value);
            $value =~ s/^\$\w+\s*=\s*//;
        }
        $str .= ", " if $i > 0;
        $str .= $_[$i] ."=". $value
    }
    return $str;
}

