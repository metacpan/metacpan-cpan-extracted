use Test::Most;
use Test::OpenTracing::Interface::Span qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::Span');

done_testing();


package MyStub::Span;
use Moo;

BEGIN { with 'OpenTracing::Role::Span' }
