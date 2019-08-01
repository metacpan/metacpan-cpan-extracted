use Test::More;
use lib '.';
use Progressive::Web::Application;

subtest root => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application->new({
		root => 't/',
	}));
	my $manifest = $pwa->set_manifest(
		name => 'test application',
		short_name => 'test',
		start_url => '/',
		icons => 't/resources',
		display => 'standalone',
		background_color => '#dadada',
		theme_color => '#dadada'
	);
	my $expected = {
		'background_color' => '#dadada',
		'display' => 'standalone',
		'icons' => [
			{
				'sizes' => '36x36',
				'src' => '/resources/36x36-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '310x310',
				'src' => '/resources/320x320-icon.png',
				'type' => 'image/png'
			}
		],
		'name' => 'test application',
		'short_name' => 'test',
		'start_url' => '/',
		'theme_color' => '#dadada'
	};
	is_deeply(
		$manifest,
		$expected,
		'set_manifest true'
	);
};

subtest 'root-and-pathpart' => sub {
	plan tests => 3;
	ok(my $pwa = Progressive::Web::Application->new({
		root => 't/',
		pathpart => 'payment',
		manifest => {
			name => 'test application',
			short_name => 'test',
			start_url => '/payment/endpoint',
			icons => 't/resources',
			display => 'standalone',
			background_color => '#dadada',
			theme_color => '#dadada'
		},
		params => {
			files_to_cache => {
				directory => ['t/resources/things']
			}
		}
	}));
	my $expected = {
		'background_color' => '#dadada',
		'display' => 'standalone',
		'icons' => [
			{
				'sizes' => '36x36',
				'src' => '/payment/resources/36x36-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '310x310',
				'src' => '/payment/resources/320x320-icon.png',
				'type' => 'image/png'
			}
		],
		'name' => 'test application',
		'short_name' => 'test',
		'start_url' => '/payment/endpoint',
		'theme_color' => '#dadada'
	};
	is_deeply(
		$pwa->manifest,
		$expected,
		'set_manifest true'
	);
	is_deeply(
		$pwa->{params}->{files_to_cache},
		[
			'/payment/resources/things/one.js',
			'/payment/resources/things/two.js'
		]
	);
};

subtest 'set_all_root-and-pathpart-and-manifest-and-params' => sub {
	plan tests => 7;
	ok(my $pwa = Progressive::Web::Application->new(), 'new');
	ok($pwa->set_root('t/'), 'set root');
	ok($pwa->set_pathpart('payment'), 'set pathpart');
	ok($pwa->set_manifest({
		name => 'test application',
		short_name => 'test',
		start_url => '/payment/endpoint',
		icons => 't/resources',
		display => 'standalone',
		background_color => '#dadada',
		theme_color => '#dadada'
	}), 'set manifest');
	ok($pwa->set_params({
		files_to_cache => {
			directory => ['t/resources/things']
		}
	}), 'set params');
	my $expected = {
		'background_color' => '#dadada',
		'display' => 'standalone',
		'icons' => [
			{
				'sizes' => '36x36',
				'src' => '/payment/resources/36x36-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '310x310',
				'src' => '/payment/resources/320x320-icon.png',
				'type' => 'image/png'
			}
		],
		'name' => 'test application',
		'short_name' => 'test',
		'start_url' => '/payment/endpoint',
		'theme_color' => '#dadada'
	};
	is_deeply(
		$pwa->manifest,
		$expected,
		'set_manifest true'
	);
	is_deeply(
		$pwa->{params}->{files_to_cache},
		[
			'/payment/resources/things/one.js',
			'/payment/resources/things/two.js'
		]
	);
};


done_testing();
