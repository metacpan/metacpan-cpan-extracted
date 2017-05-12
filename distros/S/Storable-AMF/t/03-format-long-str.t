use lib "t";
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;
eval 'use Test::More tests => 4;';

use GrianUtils;
use File::Spec;

sub serialize{
	my @values = Storable::AMF0::freeze($_[0]);
	if (@values != 1) {
		print STDERR "many returned values\n";
		return undef;
	}
	return $values[0];
}
ok(defined(serialize([0])), "xxx");
ok(defined(Storable::AMF0::freeze([0])), "xxxx1");

my $long = 'x1y2' x 70000;

ok(defined(serialize($long)), "Can serialize big string");
is(Storable::AMF0::thaw(serialize($long)), $long, "dup long string");



