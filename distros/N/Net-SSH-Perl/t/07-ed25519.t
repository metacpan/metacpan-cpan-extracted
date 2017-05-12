#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Test::More;

use vars qw( $CFG_FILE );
BEGIN { unshift @INC, 't/' }
require 'test-common.pl';

plan tests => 5;

use_ok('Net::SSH::Perl::Key');

my $key = Net::SSH::Perl::Key->new('Ed25519');
$key = $key->keygen();
ok($key, 'Key generated');

my $data = 'This is a test message to sign';
my $sig = $key->sign($data);
ok($sig, 'Signature generated');
ok($key->verify($sig,$data), 'Signature verified');
$key = eval { Net::SSH::Perl::Key->read_private_pem('t/ed25519.key','blahblahblah') };
ok($key, 'Read key file');
