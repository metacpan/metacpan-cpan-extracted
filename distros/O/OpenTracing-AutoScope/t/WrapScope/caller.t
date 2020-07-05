use Test::Most tests => 2;
use Test::OpenTracing::Integration;
use OpenTracing::Implementation qw/Test/;

use OpenTracing::WrapScope qw/check_caller/;

sub check_caller { caller }

is scalar check_caller(), __PACKAGE__, 'scalar caller';
is_deeply [ check_caller() ], [ __PACKAGE__, __FILE__, __LINE__ ], 'list caller';
