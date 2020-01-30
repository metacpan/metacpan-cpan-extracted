use strict;
use warnings;

use Test::More;

print "\nCHECKING UNZIP:\n";
my $exit_status = undef;
eval {
  system('unzip');
  $exit_status = $?;
};
ok(defined $exit_status, "Execution of <unzip> under \"$^O\" returned an exit-status: $exit_status");
SKIP: {
  skip "unzip not found, but a path can be specified when creating the instance of Qiime2::Artifact.
  Module untestable at the moment\n" if ($exit_status);
  ok($exit_status == 0, "Execution of <unzip> returned 0: expected behaviour under Linux/Darwin");
  use_ok 'Qiime2::Artifact';
}


done_testing();
