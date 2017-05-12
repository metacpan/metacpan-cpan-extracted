#!/usr/bin/perl

##
## Tests for Petal::Utils :hash modifiers
##

use blib;
use strict;
#use warnings;

use Test::More qw( no_plan );

use Carp;
use t::LoadPetal;

use Petal::Utils qw( :hash );

my $hash = {
	keys_hash_ref => {
		kkey1 => 'kvalue1',
		kkey2 => 'kvalue2',
		kkey3 => 'kvalue3',
	},
	each_hash_ref => {
		ekey1 => 'evalue1',
		ekey2 => 'evalue2',
		ekey3 => 'evalue3',
	},
};
my $template = Petal->new('hash.html');
my $out      = $template->process( $hash );

# Each
like($out, qr/ekey1 => evalue1/, 'each');
like($out, qr/ekey2 => evalue2/, 'each');
like($out, qr/ekey3 => evalue3/, 'each');

# Keys
like($out, qr/kkey1 =>/, 'keys');
like($out, qr/kkey2 =>/, 'keys');
like($out, qr/kkey3 =>/, 'keys');

# use keys to lookup values
TODO: {
    local $TODO = 'Petal cannot use dynamic hash keys to look up values';
    like($out, qr/kkey1 => kvalue1/, 'dkeys');
}

