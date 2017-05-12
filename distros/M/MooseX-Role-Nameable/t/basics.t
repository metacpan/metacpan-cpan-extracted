#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 7;

use_ok 'MooseX::Role::Nameable';

{
	package Foo;
	use Moose;
	with 'MooseX::Role::Nameable' => {name => 'name'};
	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::Bar;
	use Moose;
	extends 'Foo';
	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::SomeDeep::LongPackageName;
	use Moose;
	extends 'Foo';
	with 'MooseX::Role::Nameable' => {name => 'parent', regex => qr{([^:]*)::[^:]*$}};
	__PACKAGE__->meta->make_immutable;
}
{
	package Foo::XXLPackageBIGNameACRONYM;
	use Moose;
	extends 'Foo';
	__PACKAGE__->meta->make_immutable;
}

is(Foo->name, 'foo', 'nameable works with unnested classes');
is(Foo::Bar->name, 'bar', 'nameable uses the most nested class by default');
is(Foo::SomeDeep::LongPackageName->name, 'long_package_name', 'nameable splits camel-case with underscores');
is(Foo::SomeDeep::LongPackageName->parent, 'some_deep', 'nameable can alter where to find the name');
is(Foo::XXLPackageBIGNameACRONYM->name, 'xxl_package_big_name_acronym', 'nameable splits acronyms from words with underscores');
is(Foo->new->name, 'foo', 'nameable works with instances');
