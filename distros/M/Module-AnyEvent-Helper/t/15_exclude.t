use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use AnyEvent;

package target;

BEGIN { Test::More::use_ok('Module::AnyEvent::Helper', qw(bind_scalar strip_async_all)) }

sub new
{
	return bless {};
}

sub func1_async
{
	my $cv = AE::cv;
	my $w; $w = AE::timer 0.1, 0, sub { undef $w; $cv->send(1); };
	return $cv;
}

sub func2_async
{
	my $cv = AE::cv;
	bind_scalar($cv, func1_async(), sub { shift->recv + 1 });
	return $cv;
}

strip_async_all(-exclude => [qw(func1)]);

package main;

my $obj = target->new;

throws_ok { $obj->func1() == 1 } qr/Can't locate/, 'exclude';
ok($obj->func2() == 2);

my $cv = AE::cv;

$cv->begin;
$obj->func1_async()->cb(sub { ok(shift->recv == 1); $cv->end; });
$cv->begin;
$obj->func2_async()->cb(sub { ok(shift->recv == 2); $cv->end; });

$cv->recv;
