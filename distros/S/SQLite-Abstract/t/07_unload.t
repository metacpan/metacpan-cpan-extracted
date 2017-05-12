# -*- perl -*-

# t/07_unload.t - check DESTROY

use Test::More tests => 2;
use SQLite::Abstract;

my $database = q/__testDATABASE__/;
my $tablename = q/__testTABLE__/;

{ open my $fh, '>', $database 
	or die "cannot open $database $!" }

my $object = SQLite::Abstract->new ($database);

eval { $object->do(q/!!!/) };

like($object->err, qr/^DBD::SQLite2::db.+?failed/, "error handler");
is($object->DESTROY, undef, "DESTROY");

unlink $database;
