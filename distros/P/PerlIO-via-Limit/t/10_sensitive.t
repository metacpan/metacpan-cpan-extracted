use strict;
use Test::More tests => 2;

use PerlIO::via::Limit sensitive => 1;
ok( PerlIO::via::Limit->sensitive, 'PerlIO::via::Limit::sensitive');

PerlIO::via::Limit->sensitive(undef);
ok( ! PerlIO::via::Limit->sensitive, 'set PerlIO::via::Limit::sensitive to undef');

1;
__END__
