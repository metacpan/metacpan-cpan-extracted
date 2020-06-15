use Test::Most;
use Test::OpenTracing::Interface::ContextReference qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::ContextReference');

done_testing();


package MyStub::ContextReference;
use Moo;

sub close    { ... }
sub get_span { ... }

BEGIN { with 'OpenTracing::Role::ContextReference' }
