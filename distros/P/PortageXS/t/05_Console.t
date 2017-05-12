#!/usr/bin/perl -w

use Test::Simple tests => 2;

use lib '../lib/';
use lib 'lib/';
use PortageXS;

my $pxs = PortageXS->new();
ok(defined $pxs,'check if PortageXS->new() works');

# - formatUseflags >
{
	my @in=qw(foo -bar baz);
	my @out=$pxs->formatUseflags(@in);
	ok(($#out+1),'formatUseflags: '.join(" ",@out));
}

