#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MooseX::YAML' => qw(Load);

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
	my $obj = Load($yml);

	isa_ok( $obj, "Foo" );

	is( $obj->oh, "hai", "simple attr" );
	is( $obj->blah, 3, "default" );
	is( $obj->extra, "yatta", "BUILD" );
}

SKIP: {
	skip "YAML::XS required", 4 unless eval { require YAML::XS };

	package XS_test;
	MooseX::YAML->import(qw(Load -xs));

	my $obj = Load($yml);

	::isa_ok( $obj, "Foo" );

	::is( $obj->oh, "hai", "simple attr" );
	::is( $obj->blah, 3, "default" );
	::is( $obj->extra, "yatta", "BUILD" );
}

SKIP: {
	skip "YAML::Syck required", 4 unless eval { require YAML::Syck };

	package Syck_test;
	MooseX::YAML->import(qw(Load -syck));

	my $obj = Load($yml);

	::isa_ok( $obj, "Foo" );

	::is( $obj->oh, "hai", "simple attr" );
	::is( $obj->blah, 3, "default" );
	::is( $obj->extra, "yatta", "BUILD" );
}

SKIP: {
	skip "YAML required", 4 unless eval { require YAML };

	package PP_test;
	MooseX::YAML->import(qw(Load -pp));

	my $obj = Load($yml);

	::isa_ok( $obj, "Foo" );

	::is( $obj->oh, "hai", "simple attr" );
	::is( $obj->blah, 3, "default" );
	::is( $obj->extra, "yatta", "BUILD" );
}
