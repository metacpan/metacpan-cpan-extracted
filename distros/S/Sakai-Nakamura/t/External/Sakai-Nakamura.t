#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

my $sling_host = 'http://localhost:8080';
my $super_user = 'admin';
my $super_pass = 'admin';
my $verbose    = 0;
my $log;

BEGIN { use_ok( 'Sakai::Nakamura' ); }

my $nakamura = Sakai::Nakamura->new();
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';

$nakamura->{'URL'}     = $sling_host;
$nakamura->{'Verbose'} = $verbose;
$nakamura->{'Log'}     = $log;
$nakamura->{'User'}    = $super_user;
$nakamura->{'Pass'}    = $super_pass;
