#!/usr/bin/perl

# Tests the basic functionality of SQLite.

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use IO::Compress::Gzip ();
use URI::file          ();
use t::lib::Test;

# Flush any existing mirror database file
clear(mirror_db('ORLite::Mirror::Test'));

# Locate the broken compressed database
my $broken     = catfile(qw{ t data broken.db    });
my $broken_gz  = catfile(qw{ t data broken.db.gz });
my $broken_url = URI::file->new_abs($broken_gz)->as_string;
ok( -f $broken, 'Found test broken database' );

# Locate the stub file
my $stub     = catfile(qw{ share stub.db });
my $stub_url = URI::file->new_abs($stub)->as_string;
ok( -f $stub, 'Found test stub database' );





######################################################################
# Compile-time mirror and loading failure

SCOPE: {
	# Create the test package
	eval <<"END_PERL";
	package ORLite::Mirror::Test1;

	use strict;
	use vars qw{\$VERSION};
	BEGIN {
		\$VERSION = '1.00';
	}

	use ORLite::Mirror {
		url   => '$broken_url',
		prune => 1,
		array => 0,
	};

	1;
END_PERL

	# Did the class fail at compile time as expected
	ok( $@, 'Loading broke as expected' );
	like( $@, qr/not a database/, 'Error message matches expected' );
}





######################################################################
# Compile-time stub failure

SCOPE: {
	# Create the test package
	eval <<"END_PERL";
	package ORLite::Mirror::Test1;

	use strict;
	use vars qw{\$VERSION};
	BEGIN {
		\$VERSION = '1.00';
	}

	use ORLite::Mirror {
		url   => '$stub_url',
		stub  => '$broken',
		prune => 1,
	};

	1;
END_PERL

	# Did the class fail at compile time as expected
	ok( $@, 'Loading broke as expected' );
	like( $@, qr/not a database/, 'Error message matches expected' );
}





######################################################################
# Run-time mirror and loading failure

SCOPE: {
	# Create the test package
	eval <<"END_PERL";
	package ORLite::Mirror::Test2;

	use strict;
	use vars qw{\$VERSION};
	BEGIN {
		\$VERSION = '1.00';
	}

	use ORLite::Mirror {
		url   => '$broken_url',
		stub  => '$stub',
		prune => 1,
	};

	1;
END_PERL

	# Did the class fail at compile time as expected
	is( $@, '', 'Compiling worked as expected' );

	# It should now fail to connect-time
	eval {
		ORLite::Mirror::Test2->connect;
	};
	ok( $@, 'Loading broke as expected' );
	like( $@, qr/not a database/, 'Error message matches expected' );
}
