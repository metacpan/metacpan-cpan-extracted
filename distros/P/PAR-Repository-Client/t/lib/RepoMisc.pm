package RepoMisc;
use strict;
use warnings;
require Test::More;
use File::Temp ();
use File::Spec ();

Test::More::use_ok('PAR::Repository::Client');

# 3 tests
sub client_ok {
  my $path = shift;
  my $client = PAR::Repository::Client->new(
    uri => $path,
    verbosity => 3,
    cache_dir => $ENV{PAR_TEMP},
    checksums_timeout => 0,
  );

  Test::More::isa_ok($client, 'PAR::Repository::Client');
  Test::More::ok(!$client->error, "no error");
  return $client;
}

# 1 test
sub set_installation_targets {
  my $client = shift;
  my $dir = File::Temp::tempdir( CLEANUP => 1 );
  unshift @main::INC, $dir;

  my %targets = (
    inst_lib => $dir,
    inst_archlib => $dir,
    inst_script => $dir,
    inst_bin => $dir,
    inst_man1dir => $dir,
    inst_man3dir => $dir,
    inst_man3dir => $dir,
    packlist_read => File::Spec->catfile($dir, '.packlist'),
    packlist_write => File::Spec->catfile($dir, '.packlist'),
  );
  $client->installation_targets(%targets);
  Test::More::is_deeply(\%targets, $client->installation_targets());

  return $dir;
}

1;
