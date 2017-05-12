#!perl

use Test::More;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;
use File::Copy qw/copy/;
use Module::Build::Database::SQLite;
use FindBin;
use Path::Class qw( dir );

plan skip_all => "no sqlite executable"
    unless Module::Build::Database::SQLite->have_db_cli;

use lib $FindBin::Bin.'/tlib';
use misc qw/sysok/;

my $debug = $ENV{MBD_DEBUG} || 0;

my $dir = tempdir( CLEANUP => !$debug);
my $src_dir = "$FindBin::Bin/../eg/SqliteApp";
mkpath "$dir/db/patches";
copy "$src_dir/Build.PL", $dir;
copy "$src_dir/db/patches/0010_one.sql","$dir/db/patches";
chdir $dir;

sysok("$^X -Mblib=$FindBin::Bin/../blib Build.PL");

my $Build = dir('.')->file('Build');

sysok("$Build dbtest");

sysok("$Build dbdist");

ok -e "$dir/db/dist/base.sql", "created base.sql";
ok -e "$dir/db/dist/patches_applied.txt", "created patches_applied.txt";

# Now test dbfakeinstall and dbinstall.  Configure the database to be
# installed to a tempdir.

my $tmpdir = tempdir(CLEANUP => 0);
my $dbdir  = "$tmpdir/dbtest";

sysok("$Build dbfakeinstall");

sysok("$Build dbinstall");

#
# TODO: sqlite support needs work.
#
# my $out = `echo ".schema one" | sqlite3 sqlite_app.db`;
#
# diag $out;
chdir "$dir/..";

done_testing();

1;

