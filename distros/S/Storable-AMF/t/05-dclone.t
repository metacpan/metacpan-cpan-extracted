use lib 't';
# vim: ts=8 et sw=4 sts=4
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF0;
eval 'use Test::More tests => 16;';

use GrianUtils;
use File::Spec;

package Test::Bless;

sub new{
	bless {foo => 'bar'};
}

package main;
sub MyDump{
	join "", map { ord >31 ? $_ : "\\x". unpack "H*", $_ }  split "", $_[0];
}
my $obj = Test::Bless->new();
sub copy_test{
	my $val = shift;
	my $copy = Storable::AMF0::dclone($val);
	is_deeply($copy, $val);
}
my @objects = (undef, 0, 1, 2, 3, "hello world", "Ïðèâåò", \(my $s= "hello"), \(my $r=0), \(my $p = \(my $q)));
copy_test($_) foreach @objects;
@objects = ([], {}, [1], {a=> 2}, bless({}, "Test::Bless"), bless([], "Test::Bless"));
copy_test($_) foreach @objects;


