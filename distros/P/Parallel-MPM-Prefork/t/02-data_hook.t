#!perl -T

use Test::More tests => 3;
use Parallel::MPM::Prefork;

my $cpid;
my $data = 'Bazinga!';
my $exit_code = 42;

my $cpid_read;
my $data_read;
my $exit_code_read;

test_data_hook();

ok( $cpid_read == $cpid, 'data_hook child pid' )
  or diag("expected:$cpid got:$cpid_read");

ok( $$data_read eq $data, 'data_hook data' )
  or diag("expected:$data got:$$data_read");

ok( $exit_code_read == $exit_code, 'data_hook exit_code' )
  or diag("expected:$exit_code got:$exit_code_read");

sub test_data_hook {
  pf_init(
    min_spare_servers => 1,
    max_spare_servers => 2,
    start_servers => 1,
    data_hook_in_main => 1,
    child_data_hook => sub {
      ($cpid_read, $data_read, $exit_code_read) = @_
    },
  );

  for (1) {
    ($cpid = pf_kid_new()) && (last) // die "Could not fork: $!";
    pf_kid_exit($exit_code, \$data, 1);
  }

  waitpid $cpid, 0;
  pf_done();
}
