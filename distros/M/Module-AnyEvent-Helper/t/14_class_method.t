use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use AnyEvent;

package target;

use Module::AnyEvent::Helper;

sub new { return bless {}; }

sub func1_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send('Test'); };
	return $cv;
}

sub func2_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(1,2); };
	return $cv;
}

sub func3_async
{
	my $cv = AE::cv;
	my ($self, $arg) = @_;
	Module::AnyEvent::Helper->bind_scalar($cv, func1_async(), sub {
		die 'Exception by 3' if $arg == 3;
		return shift->recv if $arg == 1;
		Module::AnyEvent::Helper->bind_array($cv, func2_async(), sub {
			die 'Exception by 4' if $arg == 4;
			return shift->recv if $arg == 2;
		});
	});
	return $cv;
}


Module::AnyEvent::Helper->strip_async_all;

package main;

my $obj = target->new;
is($obj->func3(1), 'Test', 'simple call');
is_deeply([$obj->func3(2)], [1,2], 'nested call');
throws_ok { $obj->func3(3) } qr/Exception by 3/, 'exception';
throws_ok { $obj->func3(4) } qr/Exception by 4/, 'nested exception';
