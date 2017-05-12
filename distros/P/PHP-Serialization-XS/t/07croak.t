#!/usr/bin/env perl
use strict;
use warnings;

use PHP::Serialization::XS;
use Test::More tests => 1;

my $s = 's:3;"ABC";';
eval q{
	my $u = PHP::Serialization::XS::unserialize($s);
};
like($@, qr/ERROR/, 'dies');
