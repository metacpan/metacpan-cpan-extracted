#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/../example/lib";
use Test::More tests => 12;

BEGIN{
	package Foo;
	use parent qw(Attribute::Exporter);

	sub banana :Export(fruits){
		'banana';
	}

	sub apple :Exportable(fruits){
		'apple';
	}

	sub orange :Exportable(fruits){
		'orange';
	}

	sub xxx :Exportable{
		'xxx';
	}

	$INC{'Foo.pm'}++;
}

package X;
use Test::More;
use Foo;

ok  defined &banana;
ok !defined &apple;
ok !defined &orange;
ok !defined &xxx;

package Y;
use Test::More;
use Foo qw(:fruits);

ok  defined &banana;
ok  defined &apple;
ok  defined &orange;
ok !defined &xxx;

package Z;
use Test::More;
use Foo qw(:all);

ok  defined &banana;
ok  defined &apple;
ok  defined &orange;
ok  defined &xxx;
