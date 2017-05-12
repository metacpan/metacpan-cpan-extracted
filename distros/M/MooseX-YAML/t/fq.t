#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

require_ok 'MooseX::YAML';

{
	package Foo;
	use Moose;

	has oh => ( is => "ro", isa => "Str" );
	has blah => ( is => "ro", default => 3 );
	has extra => ( is => "rw" );

	sub BUILD { shift->extra("yatta") }
}

my $yml = <<YAML;
--- !!perl/hash:Foo
oh: hai
YAML

{
	my $obj = MooseX::YAML::Load($yml);

	isa_ok( $obj, "Foo" );

	is( $obj->oh, "hai", "simple attr" );
	is( $obj->blah, 3, "default" );
	is( $obj->extra, "yatta", "BUILD" );
}
