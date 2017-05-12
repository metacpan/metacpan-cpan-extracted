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

	$t->origin->store('foo', 'bar');
	is($t->fetch('foo'), 'bar');
	# filled with the data from origin
	is($t->cache->[0]->fetch('foo'), 'bar');
	is($t->cache->[1]->fetch('foo'), 'bar');
	
};

subtest 'not access to origin if caches have session', sub {
	my $t = Plack::Session::Store::Transparent->new(
		origin => t::lib::HashSession->new(dies_on_fetch => 1),
		cache => [
			t::lib::HashSession->new,
			t::lib::HashSession->new,
		]
	);

	$t->store('foo', 'bar');
	lives_ok {
		is($t->fetch('foo'), 'bar');
	};
	
};

done_testing;

