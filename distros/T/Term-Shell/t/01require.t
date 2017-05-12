use strict;
use warnings;

use Test::More tests => 1;

use Term::Shell;

my $shell = Term::Shell->new;

# TEST
ok ($shell, "A Term::Shell instance was initialised.");
