use strict;
use warnings;
use Test::More tests => 57;

use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }

BEGIN { use_ok('PAR::Repository::Client') };

chdir('t') if -d 't';
push @INC, 'lib', File::Spec->catdir(qw(t lib));
require RepoMisc;

my $client = RepoMisc::client_ok( File::Spec->catdir('data', 'emptyrepo') );

# should need a dbm update now:
ok($client->need_dbm_update(), "need dbm update at start");
ok(!$client->error, "no error");

ok(!$client->require_module("FunnyTestModule"), 'FunnyTestModule could not be loaded');
ok($client->error, "error after failed require");
$client->{error} = undef;
$@ = undef;

ok(!$client->need_dbm_update(PAR::Repository::Client::MODULES_DBM_FILE()), "don't need modules dbm update");
ok(!$client->error, "no error");
ok($client->need_dbm_update(PAR::Repository::Client::SCRIPTS_DBM_FILE()), "need scripts dbm update");
ok(!$client->error, "no error");
ok($client->need_dbm_update(PAR::Repository::Client::DEPENDENCIES_DBM_FILE()), "need deps dbm update");
ok(!$client->error, "no error");

ok($client->need_dbm_update(), "need dbm update");
ok(!$client->error, "no error");

# test the dbms:
my ($mdbm, $mdbmfile) = $client->modules_dbm();
ok(!$client->error, "no error");
ok(defined($mdbm));
ok(defined($mdbmfile) && -f $mdbmfile);

my ($sdbm, $sdbmfile) = $client->scripts_dbm();
ok(!$client->error, "no error");
ok(defined($sdbm));
ok(defined($sdbmfile) && -f $sdbmfile);

my ($ddbm, $ddbmfile) = $client->dependencies_dbm();
ok(!$client->error, "no error");
ok(defined($ddbm));
ok(defined($ddbmfile) && -f $ddbmfile);

ok(!$client->need_dbm_update(PAR::Repository::Client::MODULES_DBM_FILE()), "no need for update while dbm is open");
ok(!$client->error, "no error");
ok(!$client->need_dbm_update(PAR::Repository::Client::SCRIPTS_DBM_FILE()), "no need for update while dbm is open");
ok(!$client->error, "no error");
ok(!$client->need_dbm_update(PAR::Repository::Client::DEPENDENCIES_DBM_FILE()), "no need for update while dbm is open");
ok(!$client->error, "no error");

is_deeply($mdbm, {}, "modules dbm is empty");
is_deeply($sdbm, {}, "scripts dbm is empty");
is_deeply($ddbm, {}, "deps dbm is empty");

undef $mdbm;
undef $sdbm;
$client->close_modules_dbm();
ok(!$client->error, "no error");
$client->close_scripts_dbm();
ok(!$client->error, "no error");
$client->close_dependencies_dbm();
ok(!$client->error, "no error");

ok($client->need_dbm_update(), "need dbm update after closing them");
ok(!$client->error, "no error");

ok($client->need_dbm_update(PAR::Repository::Client::MODULES_DBM_FILE()), "need dbm update");
ok(!$client->error, "no error");
ok($client->need_dbm_update(PAR::Repository::Client::SCRIPTS_DBM_FILE()), "need dbm update");
ok(!$client->error, "no error");
ok($client->need_dbm_update(PAR::Repository::Client::DEPENDENCIES_DBM_FILE()), "need dbm update");
ok(!$client->error, "no error");

# now some tests which I don't know where to put:
require Config;
is($client->architecture(), $Config::Config{archname});
ok(!$client->error, "no error");
is($client->perl_version(), $Config::Config{version});
ok(!$client->error, "no error");

is($client->architecture("foo"), "foo");
ok(!$client->error, "no error");
is($client->architecture(), "foo");
ok(!$client->error, "no error");

is($client->perl_version("9.9.1"), "9.9.1");
ok(!$client->error, "no error");
is($client->perl_version(), "9.9.1");
ok(!$client->error, "no error");

