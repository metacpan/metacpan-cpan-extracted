use strict;
use warnings;
use Test::More tests => 33;

use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }

BEGIN { use_ok('PAR::Repository::Client') };


chdir('t') if -d 't';
push @INC, 'lib', File::Spec->catdir(qw(t lib));
require RepoMisc;

{
  # unsuccessful load
  my $client = RepoMisc::client_ok( File::Spec->catdir('data', 'repo_with_incompatible_module') );

  ok($client->modules_dbm(), 'module_dbm available');
  
  # private
  my $local_par_file = $client->_fetch_module('FunnyTestModule');
  ok($client->error, "error as expected");
  ok(!defined $local_par_file, '_fetch_module returned no file name');

  ok(!$client->require_module("FunnyTestModule"), 'FunnyTestModule could not be loaded');
  ok($client->error, "no error after require");
  ok(!exists($INC{FunnyTestModule}), 'FunnyTestModule not loaded');
}

{
  # successful load
  my $client = RepoMisc::client_ok( 'data/repo_with_compatible_module' );

  ok($client->modules_dbm(), 'module_dbm available');
  
  # private
  my $local_par_file = $client->_fetch_module('FunnyTestModule');
  ok(defined $local_par_file, '_fetch_module returned file name');
  ok(!$client->error, "no error after _fetch_module") or diag("Error: ".$client->error);
  ok(-f $local_par_file, '_fetch_module returned file name of existing file');

  ok($client->require_module("FunnyTestModule"), 'FunnyTestModule could be loaded');
  ok(!$client->error, "no error after require") or diag("Error: ".$client->error);
  ok(exists $INC{"FunnyTestModule.pm"}, 'FunnyTestModule loaded');
  can_ok('FunnyTestModule', 'funny');
  is(FunnyTestModule->VERSION, '5.67', 'FunnyTestModule VERSION okay');

  ok(!$client->need_dbm_update(PAR::Repository::Client::MODULES_DBM_FILE()), "don't need modules dbm update");
  ok(!$client->error, "no error") or diag("Error: ".$client->error);
  ok($client->need_dbm_update(PAR::Repository::Client::SCRIPTS_DBM_FILE()), "need scripts dbm update");
  ok(!$client->error, "no error") or diag("Error: ".$client->error);

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
}

