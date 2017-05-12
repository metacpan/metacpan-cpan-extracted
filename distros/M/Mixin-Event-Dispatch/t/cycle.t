use strict;
use warnings;

package EventTest;
use parent qw(Mixin::Event::Dispatch);

sub new { bless {}, shift }
sub cycle_step { my $self = shift; 0; }

package main;
use Test::More;
use Scalar::Util qw(weaken);
if(!eval { require Test::Memory::Cycle; }) {
	plan skip_all => 'Test::Memory::Cycle not installed';
} elsif(!eval { require PadWalker; }) {
# need this as well otherwise we get this error in tests:
#  A code closure was detected in but we cannot check it unless the PadWalker module is installed
	plan skip_all => 'PadWalker not installed';
} else {
	Test::Memory::Cycle->import;
	plan tests => 7;
}

my $obj = new_ok('EventTest');
weaken (my $obj_weak = $obj);
ok($obj->add_handler_for_event('cycle' => sub { $obj->cycle_step }), 'add handler with cycle');
memory_cycle_exists($obj);
ok($obj->invoke_event('cycle'), 'run an event to clear handler');
memory_cycle_ok($obj);
ok($obj->add_handler_for_event('no_cycle' => sub { $obj_weak->cycle_step }), 'add handler without a cycle');
memory_cycle_ok($obj);

