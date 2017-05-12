use strict;
use warnings;
use Test::More;
use Test::Exception;
use Plack::Session::Store::Transparent;

use t::lib::HashSession;

subtest 'simple', sub {
	my $t = Plack::Session::Store::Transparent->new(
		origin => t::lib::HashSession->new,
		cache => [
			t::lib::HashSession->new,
			t::lib::HashSession->new,
		]
	);
	lives_ok {
		$t->store('foo', 'bar');
	};
	
	is($t->origin->fetch('foo'), 'bar');
	is($_->fetch('foo'), 'bar') for @{ $t->cache };
};

subtest 'rollback', sub {
	my $t = Plack::Session::Store::Transparent->new(
		origin => t::lib::HashSession->new,
		cache => [
			t::lib::HashSession->new,
			t::lib::HashSession->new(dies_on_store => 1),
		]
	);
	$t->origin->store('foo', 'baz');

	throws_ok {
		$t->store('foo', 'bar');
	} qr/die for testing in store/;
	
	ok($t->fetch('foo'), 'baz');
	is($t->origin->fetch('foo'), 'baz');
	ok(! $t->cache->[0]->fetch('foo'));
	ok(! $t->cache->[1]->fetch('foo'));
};

done_testing;

