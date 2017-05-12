use strict;
use warnings;
use Test::More tests => 1;
use Test::Deep;

use Pod::Elemental;

my $document = Pod::Elemental->read_file('t/eg/one-with-everything.pod');

ok(1);
