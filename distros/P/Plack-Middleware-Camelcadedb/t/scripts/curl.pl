#!/usr/bin/perl

use strict;
use HTTP::Tiny;
use HTTP::CookieJar;
use Storable qw(freeze);

my $jar = HTTP::CookieJar->new;

$jar->add($ARGV[0], $ARGV[1]) if $ARGV[1];

my $ua = HTTP::Tiny->new(cookie_jar => $jar);
my $response = $ua->get($ARGV[0]);

print STDOUT freeze($response);
