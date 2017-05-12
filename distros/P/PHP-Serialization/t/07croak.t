#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization;
use Test::More tests => 1;

my $s = 's:3;"ABC";';
eval q{
	my $u = PHP::Serialization::unserialize($s);
};
like($@, qr/ERROR/, 'dies');
