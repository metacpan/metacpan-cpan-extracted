#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Net::Pcap;
use Sniffer::HTTP;
use Net::Pcap::FindDevice;
use Data::Dumper;

=head1 NAME

live-http-headers.pl - Dump the headers of HTTP connections as they happen

=head1 SYNTAX

  live-http-headers.pl INTERFACE

C<INTERFACE> is the name of the interface, or on Windows, a substring
of the description of the interface. If none is given, the program
defaults to C<any> on Linux and dies on Windows.

=cut

my $VERBOSE = 0;

my $device = $ARGV[0];


if ($^O =~ /MSWin32|cygwin/ && $device) {
 $device = qr/$device/i
};

my $sniffer = Sniffer::HTTP->new(
  callbacks => {
      request  => sub { my ($req,$conn) = @_; print ">>".">\n", $req->as_string },
      response => sub { my ($res,$req,$conn) = @_; print "<<"."<\n", $res->status_line,"\n",$res->headers->as_string },
      log      => sub { print $_[0] if $VERBOSE },
      tcp_log  => sub { print $_[0] if $VERBOSE > 1 },
  }
)->run( $device, $ARGV[1] );