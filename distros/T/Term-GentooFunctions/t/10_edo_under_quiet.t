use strict;
no warnings;

use Test;
use Term::GentooFunctions qw(:all);

plan tests => (my $tests = 1);

equiet(1);

ok( edo(test=>sub { 7_7 }), 77 );
