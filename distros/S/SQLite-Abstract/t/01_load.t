# -*- perl -*-

# t/01_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'SQLite::Abstract' ); }

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

{ open my $fh, '>', $database 
	or die "cannot open $database $!" }

my $object = SQLite::Abstract->new ($database);

isa_ok ($object, 'SQLite::Abstract');
