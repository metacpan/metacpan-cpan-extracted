
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use 5.012;
use warnings;
use Proch::N50;
use Test::More;
use Data::Dumper;
use FindBin qw($RealBin);
use File::Spec::Functions;
use lib $RealBin;
use TestFu;
use IPC::Cmd qw(run);

my ($ok, $output, $err) = run_bin("fu-say");
ok($output eq "OK", "Testing external programs is OK");
chomp($output);
chomp($err);
say STDERR "out={", $output, "}";
say STDERR "err=[[", $err, "]]";
done_testing();
