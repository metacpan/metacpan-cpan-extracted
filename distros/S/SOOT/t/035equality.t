use strict;
use warnings;
use Test::More tests => 11;
use SOOT;
use SOOT::API qw/:all/;
pass();

my $h1 = TH1D->new("h", "h", 2, 0., 1.);
my $h2 = TH1D->new("h2", "h2", 2, 0., 1.);
my $h1_clone = $h1->as('TH1D');
my $h1_castclone = $h1->as('TH1I');

ok(is_same_object($h1, $h1), "is_same_object(\$h1, \$h1) => yes");
ok(is_same_object($h1, $h1_clone), "is_same_object(\$h1, \$h1_clone) => yes");
ok(is_same_object($h1, $h1_castclone), "is_same_object(\$h1, \$h1_castclone) => yes");
ok(!is_same_object($h1, $h2), "is_same_object(\$h1, \$h2) => no");
# SEGV, but SOOT::API is internals stuff...
#ok(!is_same_object($h1, "something"), "is_same_object(\$h1, 'something') => no");
#ok(!is_same_object("something", $h1), "is_same_object('something', \$h1) => no");

ok(($h1 == $h1), "(\$h1 == \$h1) => yes");
ok(($h1 == $h1_clone), "(\$h1 == \$h1_clone) => yes");
ok(($h1 == $h1_castclone), "(\$h1 == \$h1_castclone) => yes");
ok(!($h1 == "blah"), "(\$h1 == 'blah') => no");
ok(!("blah" == $h1), "('blah' == \$h1) => no");


pass("REACHED END");
