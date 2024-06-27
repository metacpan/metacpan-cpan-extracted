use 5.022;
use warnings;
use strict;

use Test::More;
use lib qw< tlib t/tlib >;

use Multi::Dispatch;

my $exception;
BEGIN { ok !eval{ require CompErr::ReturnInDefault;   }; $exception = $@; }
BEGIN { like $exception, qr/Default value for parameter \$opt cannot include a 'return' statement/, 'ReturnInDefault' }

done_testing();


