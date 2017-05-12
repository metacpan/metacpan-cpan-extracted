use strict;
use warnings;
use Test::More tests => 10;

use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }

BEGIN { use_ok('PAR::Repository::Client') };


chdir('t') if -d 't';
push @INC, 'lib', File::Spec->catdir(qw(t lib));
require RepoMisc;

{
  # successful load
  my $client = RepoMisc::client_ok( File::Spec->catdir('data', 'repo_with_compatible_module') );

  my $idir = RepoMisc::set_installation_targets($client);
  
  ok($client->install_module("FunnyTestModule"), 'FunnyTestModule was installed');
  require FunnyTestModule;
  ok(!$client->error, "no error after install") or diag("Error: ".$client->error);
  ok(exists $INC{"FunnyTestModule.pm"}, 'FunnyTestModule loaded');
  can_ok('FunnyTestModule', 'funny');
  is(FunnyTestModule->VERSION, '5.67', 'FunnyTestModule VERSION okay');
}

