use Test::More tests => 1;

use strict;
use warnings;

use Path::Class::Iterator;

my $root = 'nosuchdir';
my $walker = Path::Class::Iterator->new(root => $root);
ok(! defined $walker, "new object failed on non-existent dir");
