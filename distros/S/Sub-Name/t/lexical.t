use strict;
use warnings;

use Test::More;
BEGIN {
  if ("$]" < 5.018) {
    plan 'skip_all' => 'lexical subs not supported on this perl';
  }
}

BEGIN {
  if ("$]" < 5.020) {
    plan 'skip_all' => 'lexical subs unreliable on this perl';
  }
}

use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';

use Sub::Name;

local $TODO = "lexical subs unnameable until perl 5.22"
  unless "$]" >= 5.022;

my $foo = sub { (caller 0)[3] };

my sub foo { (caller 0)[3] }

subname 'main::foo2' => \&foo;
is foo(), 'main::foo2', 'lexical subs can be named';

my $x = 3;
my sub bar { (caller 0)[$x] }
subname 'main::bar2' => \&bar;
is bar(), 'main::bar2', 'lexical closure subs can be named';

done_testing;
