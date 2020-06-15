use Test::Most;
use Test::OpenTracing::Interface::Scope qw/can_all_ok/;

use strict;
use warnings;

can_all_ok('MyStub::Scope');

done_testing();


package MyStub::Scope;
use Moo;

sub close    { ... }
sub get_span { ... }

BEGIN { with 'OpenTracing::Role::Scope' }
