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
use t::lib::Test;

# Where will the cache file be written to
my $orlite_version = $t::lib::Test::VERSION;
$orlite_version =~ s/[\._]/-/g;
my $cached = catfile( 
	"t",
	"Foo-Bar-1-23-ORLite-$orlite_version-user_version-2.pm",
);
clear($cached);
ok( ! -e $cached, 'Cache file does not initially exist' );

# Set up the database
my $file = test_db();
my $dbh  = create_ok(
	file    => catfile(qw{ t 17_cache.sql }),
	connect => [ "dbi:SQLite:$file" ],
);

# Create the test package
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use vars qw{\$VERSION};
BEGIN {
	\$VERSION = '1.23';
}

use ORLite {
	file         => '$file',
	cache        => 't',
	user_version => 2,
};

1;
END_PERL

# Check some basics
$file = rel2abs($file);
is( Foo::Bar->sqlite, $file,              '->sqlite ok' );
is( Foo::Bar->dsn,    "dbi:SQLite:$file", '->dsn ok'    );

# Did the cache file get created?
ok( -f $cached, "Cache file $cached created" );
my $inc1 = scalar keys %INC;

# Delete the generated class (using hacky inlined Class::Unload)
SCOPE: {
	no strict 'refs';
	
	ok( Foo::Bar->VERSION, 'Foo::Bar exists' );
	my $symtab = "Foo::Bar::";
	@Foo::Bar::ISA = ();
	for my $symbol ( keys %$symtab ) {
		delete $symtab->{$symbol};
	}
}

# Load the class again
eval <<"END_PERL"; die $@ if $@;
package Foo::Bar;

use strict;
use vars qw{\$VERSION};
BEGIN {
	\$VERSION = '1.23';
}

use ORLite {
	file         => '$file',
	cache        => 't',
	user_version => 2,
};

1;
END_PERL

# Did it load the second time?
is( Foo::Bar->sqlite, $file,              '->sqlite ok' );
is( Foo::Bar->dsn,    "dbi:SQLite:$file", '->dsn ok'    );

# There should be one extra entry now
my $inc2 = scalar keys %INC;
is( $inc2, $inc1 + 1, '%INC is larger by one from cache' );
