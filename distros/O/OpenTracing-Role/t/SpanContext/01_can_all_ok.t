use Test::Most;
use Test::OpenTracing::Interface::SpanContext qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::SpanContext');

done_testing();


package MyStub::SpanContext;
use Moo;

BEGIN { with 'OpenTracing::Role::SpanContext' }
