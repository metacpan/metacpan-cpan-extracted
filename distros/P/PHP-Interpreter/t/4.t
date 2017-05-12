use strict;
use Test::More tests => 5;

BEGIN {
  use_ok 'PHP::Interpreter' or die;
}

diag "Test pashing hashes from Perl->PHP->Perl";

# weird include path hack
chdir('t');
ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
ok $p->include('test.inc'), "include() PHP testing functions.";
my $hash = { 'a' => 'alpha', 'b' => 'beta', 'c' => 'charlie' };
ok my $arg = $p->ident($hash), "Pass a hash into PHP, recieve a hash back";

is_deeply $arg, $hash,  "Checking the return hash matches the passed hash.";

