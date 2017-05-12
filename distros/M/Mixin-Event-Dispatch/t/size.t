use strict;
use warnings;
package EventTest;
use parent qw(Mixin::Event::Dispatch);

sub new { bless {}, shift }
sub test_event_count { shift->{seen_test_event} }
sub on_test_event {
	my $self = shift;
	++$self->{seen_test_event};
}

package main;
use Test::More;
BEGIN {
	if(!eval { require Devel::Size; }) {
		plan skip_all => 'Devel::Size not installed';
	} else {
		Devel::Size->import(qw(total_size));
		plan tests => 4;
	}
}

my $obj = new_ok('EventTest');
ok($obj->invoke_event('test_event'), 'invoke event');
my $second = 0;
ok($obj->add_handler_for_event('second_test' => sub { ++$second; 0 }), 'add handler for event');
$obj->invoke_event('second_test');

my $initial_size = total_size($obj);
note "initial size = " . $initial_size;
$obj->invoke_event('test_event') for 0..100;
$obj->invoke_event('second_test') for 0..10000;
$obj->invoke_event('test_event') for 0..1000;
is(total_size($obj), $initial_size, 'calling many events does not increase size of object');

