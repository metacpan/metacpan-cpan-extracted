#!perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN{ $ENV{SUB_ATTRIBUTE_DEBUG} = 1 }

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
	$INC{'Foo.pm'}++;
}
use Foo;

print banana(), "\n";
