use Test::More;
use strict; use warnings FATAL => 'all';

use POEx::ZMQ::FFI;

my $vers;
eval {; $vers = POEx::ZMQ::FFI->get_version->string };
if (my $err = $@) {
  if ($err =~ /(?:requires.ZeroMQ|search.path)/) {
    BAIL_OUT "OS unsupported - $err";
  } else {
    die $@
  }
}

diag "Testing against ZeroMQ $vers";
ok $vers, "System has acceptable ZMQ version: $vers";

done_testing
