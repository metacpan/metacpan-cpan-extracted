#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	# $^W = 1;
}

use Test::More tests => 11;





#####################################################################
# Test Package

my $file = 'foo.sqlite';
unlink( $file ) if -f $file;

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package My::Foo;

use strict;
use ORLite {
	file   => '$file',
	create => sub {
		my \$dbh = shift;

		# Set up the test database
		\$dbh->do( 'create table foo ( bar int not null primary key )' );
		\$dbh->do( 'pragma user_version = 2'      );
		\$dbh->do( 'insert into foo values ( 5 )'        );
		\$dbh->do( 'insert into foo values ( ? )', {}, 7 );

		return 1;
	},
	user_version => 2,
};

1;
END_PERL

# Enable profiling
require ORLite::Profile;

# Run some tests
ok( My::Foo->can('connect'), 'Created read code'  );
ok( My::Foo->can('begin'),   'Created write code' );

# Test ability to get and set pragmas
is( My::Foo->pragma('schema_version'), 1, 'schema_version is zero' );
is( My::Foo->pragma('user_version'),   2, 'Confirm user_version changed' );

# Check for the existance of the generated table and objects
my @object = My::Foo::Foo->select;
is( scalar(@object), 2, 'Found 2 Foo objects' );
isa_ok( $object[0], 'My::Foo::Foo' );
isa_ok( $object[1], 'My::Foo::Foo' );
is( $object[0]->bar, 5, '->foo ok' );
is( $object[1]->bar, 7, '->foo ok' );

# Make sure it's a full readwrite interface
my $create = My::Foo::Foo->create( bar => 3 );
isa_ok( $create, 'My::Foo::Foo' );
is( $create->bar, 3, '->bar ok' );
