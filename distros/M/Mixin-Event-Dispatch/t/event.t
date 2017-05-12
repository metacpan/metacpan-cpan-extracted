use strict;
use warnings;
package EventTest;
use parent qw(Mixin::Event::Dispatch);
use Test::More;

# Turn on the fallback to on_* event handlers
use constant EVENT_DISPATCH_ON_FALLBACK => 1;

sub new { bless {}, shift }
sub test_event_count { shift->{seen_test_event} }
sub on_test_event {
	my $self = shift;
	++$self->{seen_test_event};
}
sub on_evt_with_parameters {
	my $self = shift;
	my %args = @_;
	$self->invoke_event(parameters => [ %args ]);
}

package main;
use Test::More tests => 14;

my $obj = new_ok('EventTest');
ok($obj->invoke_event('test_event'), 'can invoke event with method available');
is($obj->test_event_count, 1, 'event count correct');
my $second = 0;
ok($obj->add_handler_for_event('second_test' => sub { ++$second; 0 }), 'can add handler for event');
is($second, 0, 'count is zero before invoking event');
ok($obj->invoke_event('second_test'), 'can invoke event with queued handler');
is($second, 1, 'count is 1 after invoking event');
is($obj->invoke_event('second_test'), $obj, 'still returns $self when handler no longer present');
is($second, 1, 'count is 1 after invoking event again');
is($obj->test_event_count, 1, 'event count correct');

ok($obj->add_handler_for_event(parameters => sub {
	my $self = shift;
	my $param_ref = shift;
	my %param = @$param_ref;
	is($param{first}, 17, 'first parameter is 17');
	is($param{second}, 'test', 'second parameter is test');
}), 'add parameters handler');
my %hash = (
	first => 17,
	second	=> 'test'
);
ok($obj->invoke_event(evt_with_parameters => %hash), 'invoke with hash');
