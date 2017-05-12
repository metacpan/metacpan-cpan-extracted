use strict;
use warnings;
use Test::More;
use File::Path qw( mkpath );
use File::Copy qw( copy );
use File::Temp qw( tempdir );
use FindBin ();
use Module::Build::Database::PostgreSQL;
use lib $FindBin::Bin.'/tlib';
use misc qw/sysok/;
use File::Spec;

# requires plperl (to install on debian wheezy: apt-get install postgresql-plperl-9.1)
plan skip_all => 'set TEST_PLPERL to enable test' unless $ENV{TEST_PLPERL};
plan skip_all => 'Cannot find postgres executable'
  if $Module::Build::Database::PostgreSQL::Bin{Postgres} eq '/bin/false';
plan skip_all => 'Cannot test postgres as root'
  unless $> or $^O eq 'MSWin32';

my @pg_version = `$Module::Build::Database::PostgreSQL::Bin{Postgres} --version` =~ / (\d+)\.(\d+)\.(\d+)$/m;

my $dir = tempdir( CLEANUP => 1);
my $src_dir = "$FindBin::Bin/../eg/Plperlapp";
mkpath "$dir/db/patches";
copy "$src_dir/Build.PL", $dir;
copy "$src_dir/db/patches/0010_one.sql","$dir/db/patches";
chdir $dir;

sysok("$^X -Mblib=$FindBin::Bin/../blib Build.PL");

sysok("./Build dbtest");

sysok("./Build dbdist");

ok -e "$dir/db/dist/base.sql", "created base.sql";
ok -e "$dir/db/dist/patches_applied.txt", "created patches_applied.txt";

# Now test dbfakeinstall and dbinstall.  Configure the database to be
# installed to a tempdir.

my $tmpdir = tempdir(CLEANUP => 0);
my $dbdir  = "$tmpdir/dbtest";

$ENV{PGPORT} = 5432;
$ENV{PGHOST} = "$dbdir";
$ENV{PGDATA} = "$dbdir";
$ENV{PGDATABASE} = "scooby";

sysok("$Module::Build::Database::PostgreSQL::Bin{Initdb} -D $dbdir");

open my $fp, ">> $dbdir/postgresql.conf" or die $!;
if ($pg_version[1] > 2) {
    print {$fp} qq[unix_socket_directories = '$dbdir'\n];
} else  {
    print {$fp} qq[unix_socket_directory = '$dbdir'\n];
}
close $fp or die $!;

sysok(qq[$Module::Build::Database::PostgreSQL::Bin{Pgctl} -t 120 -o "-h ''" -w start]);

sysok("./Build dbfakeinstall");

sysok("./Build dbinstall");

my $out = do { local $ENV{PERL5LIB}; `psql -F: -P tuples_only -P format=unaligned -c "select perl_version(),1"` };

my $regex = qr{^Perl version running in postgres (v?[\d\.]+\d+):1$};
$out =~ $regex; 
like $out, $regex, "plperl Perl version = $1";

sysok("./Build dbfakeinstall");

sysok("$Module::Build::Database::PostgreSQL::Bin{Pgctl} -D $dbdir -m immediate stop");

chdir(File::Spec->updir); # otherwise file::temp can't clean up

done_testing;
