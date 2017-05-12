use strict;
use warnings;

use Test::More tests => 2;

use lib qw( t/lib );

BEGIN { use_ok("Module::Mask", "Dummy") };

eval { require Dummy };
ok($@, 'import blocks listed module');

__END__
