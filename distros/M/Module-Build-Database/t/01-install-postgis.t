#!perl

use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Path qw/mkpath/;
use File::Copy qw/copy/;
use IO::Socket::INET;
use FindBin;
use Module::Build::Database::PostgreSQL;
use Path::Class qw( dir );

use lib $FindBin::Bin.'/tlib';
use misc qw/sysok/;

$ENV{LC_ALL} = 'C';

my $scratch_db_server = scalar grep { defined $ENV{"MBD_SCRATCH_PG$_"} } qw( HOST PORT USER );
my $test_db_server    = scalar grep { defined $ENV{"MBD_TEST_PG$_"} } qw( HOST PORT USER );

if($^O =~ /^(MSWin32|cygwin)$/ && !$scratch_db_server && !$test_db_server) {
    plan skip_all => "Must set at least one of MBD_SCRATCH_PGHOST, MBD_SCRATCH_PGPORT or MBD_SCRATCH_PGUSER on MSWin32 for this test";
}

$> or $^O eq 'MSWin32' or do {
    plan skip_all => "Cannot test postgres as root";
};

my $postg = $ENV{TEST_POSTGIS_BASE};
unless (defined $postg && -d $postg) {
    plan skip_all => "No postgis.sql, set TEST_POSTGIS_BASE to a directory containing postgis.sql to enable this test";
}

my @pg_version;

if($scratch_db_server && $test_db_server) {

    if($Module::Build::Database::PostgreSQL::Bin{Psql}  eq '/bin/false') {
        plan skip_all => "Cannot find psql executable";
    }

} else {

    if($Module::Build::Database::PostgreSQL::Bin{Postgres} eq '/bin/false') {
        plan skip_all => "Cannot find postgres executable";
    }

    @pg_version = `$Module::Build::Database::PostgreSQL::Bin{Postgres} --version` =~ / (\d+)\.(\d+)\.(\d+)$/m;

    diag "pg version : ".join '.', @pg_version;

    unless ($pg_version[0] >= 8) {
        plan skip_all => "postgres version must be >= 8.0";
    }

    if ($pg_version[0]==8 && $pg_version[1] < 4) {
        plan skip_all => "postgres version must be >= 8.4"
    }
    
    unless ($pg_version[0] >= 8) {
        plan skip_all => "postgres version must be >= 8.0";
    }

    if ($pg_version[0]==8 && $pg_version[1] < 4) {
        plan skip_all => "postgres version must be >= 8.4"
    }
}

plan qw/no_plan/;

my $debug = 0;

my $dir = tempdir( CLEANUP => !$debug);
my $src_dir = "$FindBin::Bin/../eg/Pgapp";
mkpath "$dir/db/patches";
copy "$src_dir/Build.PL", $dir;
copy "$src_dir/db/patches/0010_one.sql","$dir/db/patches";
chdir $dir;

sysok("$^X -Mblib=$FindBin::Bin/../blib Build.PL --postgis_base=$postg");

my $Build = dir('.')->file('Build');

sysok("$Build dbtest");

sysok("$Build dbdist");

ok -e "$dir/db/dist/base.sql", "created base.sql";
ok -e "$dir/db/dist/patches_applied.txt", "created patches_applied.txt";

# Now test dbfakeinstall and dbinstall.  Configure the database to be
# installed to a tempdir.

my $tmpdir = tempdir(CLEANUP => 0);
my $dbdir  = "$tmpdir/dbtest";

$ENV{PGDATABASE} = "scooby";

my $psql = $Module::Build::Database::PostgreSQL::Bin{Psql};

if($test_db_server) {
    foreach my $key (qw( PGHOST PGPORT PGUSER )) {
        if(defined $ENV{"MBD_TEST_$key"}) {
            $ENV{$key} = $ENV{"MBD_TEST_$key"};
        } else {
            delete $ENV{$key};
        }
    }
    if(scalar grep /^scooby$/, map { [split /:/]->[0] } `$psql -Alt -F:`) {
        sysok("$Module::Build::Database::PostgreSQL::Bin{Dropdb} scooby");
    }
} else {
    $ENV{PGPORT} = 5432;
    $ENV{PGHOST} = "$dbdir";
    $ENV{PGDATA} = "$dbdir";


    sysok("$Module::Build::Database::PostgreSQL::Bin{Initdb} -D $dbdir");

    open my $fp, ">> $dbdir/postgresql.conf" or die $!;
    if ($pg_version[1] > 2) {
        print {$fp} qq[unix_socket_directories = '$dbdir'\n];
    } else  {
        print {$fp} qq[unix_socket_directory = '$dbdir'\n];
    }
    close $fp or die $!;

    sysok(qq[$Module::Build::Database::PostgreSQL::Bin{Pgctl} -t 120 -o "-h ''" -w start]);
}

sysok("$Build dbfakeinstall");

sysok("$Build dbinstall");

my $out = do { local $ENV{PERL5LIB}; `$psql -c "\\d one"` };

like $out, qr/table.*doo\.one/i, "made table one in schema doo";
like $out, qr/x.*integer/, "made column x type integer";

unless($test_db_server) {
    sysok("$Module::Build::Database::PostgreSQL::Bin{Pgctl} -D $dbdir -m immediate stop") unless $debug;
}

chdir '..'; # otherwise file::temp can't clean up

1;

