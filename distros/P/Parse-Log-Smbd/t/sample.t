#!/usr/bin/perl 

use strict;
use warnings;

use Test::More tests => 6;

use_ok('Parse::Log::Smbd');

my $log = Parse::Log::Smbd->new( 't/samples/log.smbd.sample' );

isa_ok($log, "Parse::Log::Smbd");

ok(my @users = $log->users, "got users");
ok(my @shares = $log->shares, "got shares");
is(scalar @users, 30, "got 30 users");
is(scalar @shares, 33, "got 33 shares");
