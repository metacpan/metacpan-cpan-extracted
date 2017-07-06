#!/usr/bin/perl

use Test::More tests => 1;

use PHP::Serialization::XS;

my $data = {
	a => undef,
	b => [],
	c => {},
};
my $exp = {
    a => undef,
    b => undef,
    c => undef,
};

my $x = PHP::Serialization::XS->new(prefer_undef => 1);
my $encoded = $x->encode($data);
is_deeply($exp, $x->decode($encoded));
