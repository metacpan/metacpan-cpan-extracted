use Test::More;
use lib '.';
use Progressive::Web::Application;
subtest empty_new => sub {
	plan tests => 1;
	ok(Progressive::Web::Application->new());
};

subtest set_params-offline_path => sub {
	plan tests => 4;
	ok(my $pwa = Progressive::Web::Application->new({
		params => {
			offline_path => '/test/one'
		}
	}), 'new');
	is($pwa->{params}{offline_path}, '/test/one', 'okay instantiate with offline_path');
	ok($pwa->set_params({
		offline_path => '/test/two'
	}), 'set_precache');
	is($pwa->{params}{offline_path}, '/test/two', 'okay set offline_path via set_precache');
};

subtest set_params-files_to_cache-array => sub {
	plan tests => 4;
	ok(my $pwa = Progressive::Web::Application->new({
		params => {
			files_to_cache => [
				'a',
				'b',
				'c'
			],
		}
	}), 'new Array');
	is_deeply(
		$pwa->{params}{files_to_cache},
		[
			'a',
			'b',
			'c'
		],
		'instantiate with files_to_cache as array'
	);
	ok($pwa->set_params({
		files_to_cache => [
			'd',
			'e',
			'f'
		]
	}), 'set files_to_cache via set_params as an ARRAY');
	is_deeply(
		$pwa->{params}{files_to_cache},
		[
			'd',
			'e',
			'f'
		],
		'set files_to_cache as array'
	);
};

subtest set_params-files_to_cache-code => sub {
	plan tests => 4;
	ok (my $pwa = Progressive::Web::Application->new({
		params => {
			files_to_cache => sub {
				return [
					'a',
					'b',
					'c'
				];
			}
		}
	}), 'new code');
	is_deeply(
		$pwa->{params}{files_to_cache},
		[
			'a',
			'b',
			'c'
		],
		'instantiate with files_to_cache as array'
	);
	ok($pwa->set_params({
		files_to_cache => sub { 
			return [
				'd',
				'e',
				'f'
			];
		}
	}), 'set files_to_cache via set_params as an ARRAY');
	is_deeply(
		$pwa->{params}{files_to_cache},
		[
			'd',
			'e',
			'f'
		],
		'set files_to_cache as array'
	);
};

subtest set_params-files_to_cache-death => sub {
	plan tests => 2;
	is(eval { Progressive::Web::Application->new({
		params => {
			files_to_cache => qr/not_okay/
		}
	}) }, undef, 'errors');
	like($@, qr/currently set_params files_to_cache cannot handle Regexp/, 'currently set_params files_to_cache cannot handle HASH');
};

subtest set_params-files_to_cache-with_offline_path => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application->new(
		params => {
			files_to_cache => [
				qw/b c d/
			],
			offline_path => 'a'
		}
	), 'new with files_to_cache and offline_path');
	is_deeply(
		$pwa->{params}{files_to_cache},
		[qw/a b c d/],
		'instantiate with params files_to_cache and offline_path'
	);
};

subtest cacheName => sub {
	plan tests => 4;
	ok(my $pwa = Progressive::Web::Application->new(
		params => {}
	), 'new to get default cache_name');
	is($pwa->{params}{cache_name}, 'Set-a-cache-name-v1', 'default cache name was set');
	ok($pwa->set_params({
		cache_name => 'my-cache-name'
	}), 'update cache_name');
	is($pwa->{params}{cache_name}, 'my-cache-name', 'updated cache name was set');
};

done_testing();
