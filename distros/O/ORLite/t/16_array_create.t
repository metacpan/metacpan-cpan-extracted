#!/usr/bin/perl

# The same as 06_create.t but with array => 1

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 25;
use File::Spec::Functions ':ALL';
use t::lib::Test;





#####################################################################
# Simple Test Creation

SCOPE: {
	# Set up the file
	my $file = test_db();

	# Create the test package
	eval <<"END_PERL"; die $@ if $@;
package My::Test1;

use strict;
use ORLite {
	file   => '$file',
	array  => 1,
	create => 1,
	tables => 0,
	append => 'sub append { 2 }',
};

1;
END_PERL

	ok( My::Test1->can('connect'), 'Created read code'  );
	ok( My::Test1->can('begin'),   'Created write code' );

	# Test ability to get and set pragmas
	is( My::Test1->pragma('schema_version' ), 0, 'schema_version is zero' );
	is( My::Test1->pragma('user_version' ), 0, 'user_version is zero' );
	is( My::Test1->pragma('user_version', 2 ), 2, 'Set user_version' );
	is( My::Test1->pragma('user_version' ), 2, 'Confirm user_version changed' );

	# Test that the schema_version is updated as expected
	ok( My::Test1->do('create table foo ( bar int )'), 'Created test table' );
	is( My::Test1->pragma('schema_version' ), 1, 'schema_version is zero' );

	# Test the appending of additional code
	is( My::Test1->append, 2, 'append params works as expected' );
}





#####################################################################
# Complex Test Case

SCOPE: {
	# Set up the file
	my $file = test_db();

	# Create the test package
	eval <<"END_PERL"; die $@ if $@;
package My::Test2;

use strict;
use ORLite {
	file   => '$file',
	array  => 1,
	create => sub {
		my \$dbh = shift;

		# Set up the test database
		\$dbh->do( 'create table foo ( bar int not null primary key )' );
		\$dbh->do( 'pragma user_version = 2' );
		\$dbh->do( 'insert into foo values ( 5 )' );
		\$dbh->do( 'insert into foo values ( ? )', {}, 7 );

		return 1;
	},
	user_version => 2,
};

1;
END_PERL

	# Transaction basics
	ok( My::Test2->can('connect'), 'Created read code'  );
	ok( My::Test2->can('begin'),   'Created write code' );

	# Test ability to get and set pragmas
	is( My::Test2->pragma('schema_version'), 1, 'schema_version is zero' );
	is( My::Test2->pragma('user_version'),   2, 'Confirm user_version changed' );

	# Check for the existance of the generated table and objects
	my @object = My::Test2::Foo->select;
	is( scalar(@object), 2, 'Found 2 Foo objects' );
	isa_ok( $object[0], 'My::Test2::Foo' );
	isa_ok( $object[1], 'My::Test2::Foo' );
	is( $object[0]->bar, 5, '->foo ok' );
	is( $object[1]->bar, 7, '->foo ok' );

	# Make sure it's a full readwrite interface
	my $create = My::Test2::Foo->create( bar => 3 );
	isa_ok( $create, 'My::Test2::Foo' );
	is( $create->bar, 3, '->bar ok' );
}





######################################################################
# Appending with tables

SCOPE: {
	# Set up the file
	my $file = test_db();
	my $dbh  = create_ok(
		file    => catfile(qw{ t 02_basics.sql }),
		connect => [ "dbi:SQLite:$file" ],
	);

	# Create the second test package (with tables)
	eval <<"END_PERL"; die $@ if $@;
package My::Test3;

use strict;
use ORLite {
	file   => '$file',
	array  => 1,
	create => 1,
	append => 'sub append { 2 }',
};

1;
END_PERL

	ok( My::Test3->can('connect'), 'Created read code'  );
	ok( My::Test3->can('begin'),   'Created write code' );
	ok( My::Test3::TableOne->can('select'), 'Created table code' );

	# When generating tables, we still append to the right place
	is( My::Test3->append, 2, 'append params works as expected' );
}
