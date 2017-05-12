#!/usr/bin/perl

use strict;
use warnings;

use IO::Async::Loop;
use Net::Async::Matrix;
use Net::Netrc;

use Getopt::Long;

GetOptions(
   'server=s' => \my $SERVER,
   'SSL'      => \my $SSL,
   'user=s'   => \my $USER,
   'pass=s'   => \my $PASS,

   'since=s'  => \my $SINCE,
) or exit 1;

die "Require --server\n" unless defined $SERVER;

if( !defined $PASS ) {
   my $ent = Net::Netrc->lookup( $SERVER, $USER ) or
      die "No --pass given and not found in .netrc\n";

   $USER //= $ent->login;
   $PASS //= $ent->password;
}

my $loop = IO::Async::Loop->new;

my $matrix = Net::Async::Matrix->new(
   server          => $SERVER,
   SSL             => $SSL,
   SSL_verify_mode => 0,
);
$loop->add( $matrix );

print STDERR "Logging in to $SERVER as $USER...\n";

$matrix->login(
   user_id  => $USER,
   password => $PASS,

   _no_start => 1,
)->get;

print STDERR "Requesting sync...\n";

use JSON::MaybeXS;
STDOUT->binmode( ":encoding(UTF-8)" );

print JSON::MaybeXS->new( pretty => 1 )->encode(
   scalar $matrix->sync(
      ( defined $SINCE ? ( since => $SINCE ) : () )
   )->get
);
