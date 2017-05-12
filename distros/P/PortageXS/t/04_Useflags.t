#!/usr/bin/perl -w

use Test::Simple tests => 4;

use lib '../lib/';
use lib 'lib/';
use PortageXS;

my $pxs = PortageXS->new();

# - getUsedesc >
{
	my $usedesc = $pxs->getUsedesc('perl',$pxs->portdir());
	ok($usedesc,"getUsedesc('perl','".$pxs->portdir()."'): ".$usedesc);
}

# - getUsedescs >
{
	my @usedescs = $pxs->getUsedescs('perl',$pxs->portdir());
	ok(($#usedescs+1),"getUsedescs('perl','".$pxs->portdir()."'): ".join(" ",@usedescs));
}

# - sortUseflags >
{
	my @in=qw(foo -bam bar baz);
	my @out=$pxs->sortUseflags(@in);
	ok(join(' ',@out) eq 'bar baz foo -bam','sortUseflags returned expected order: '.join(' ',@out));
}

# - getUsemasksFromProfile >
{
	my @usemasks=$pxs->getUsemasksFromProfile();
	ok(($#usemasks+1),'getUsemasksFromProfile() returned '.($#usemasks+1).' masked useflags');
}

