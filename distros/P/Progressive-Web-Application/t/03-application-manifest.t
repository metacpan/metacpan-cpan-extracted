use Test::More;
use lib '.';
use Progressive::Web::Application;
subtest empty_new => sub {
	plan tests => 1;
	ok(Progressive::Web::Application->new());
};

subtest set_manifest => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application->new());
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
				'src' => '/t/resources/36x36-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '310x310',
				'src' => '/t/resources/320x320-icon.png',
				'type' => 'image/png'
			},
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

subtest has_manifest => sub {
	plan tests => 4;
	ok(my $pwa = Progressive::Web::Application->new(
		manifest => {
			name => 'test application',
			short_name => 'test',
			start_url => '/',
			icons => 't/resources',
			display => 'standalone',
			background_color => '#dadada',
			theme_color => '#dadada'
		}
	));
	ok($pwa->has_manifest(), 'has_manifest true');
	ok(my $new = Progressive::Web::Application->new());
	ok(!$new->has_manifest(), 'has_manifest false');
};

subtest manifest => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application->new(
		manifest => {
			name => 'test application',
			short_name => 'test',
			start_url => '/',
			icons => 't/resources',
			display => 'standalone',
			background_color => '#dadada',
			theme_color => '#dadada'
		}
	));
	my $expected = {
		'background_color' => '#dadada',
		'display' => 'standalone',
		'icons' => [
			{
				'sizes' => '36x36',
				'src' => '/t/resources/36x36-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '310x310',
				'src' => '/t/resources/320x320-icon.png',
				'type' => 'image/png'
			},
		],
		'name' => 'test application',
		'short_name' => 'test',
		'start_url' => '/',
		'theme_color' => '#dadada'
	};
	is_deeply(
		$pwa->manifest(),
		$expected,
		'set_manifest true'
	);
};

subtest generate => sub {
	plan tests => 3;
	ok(my $pwa = Progressive::Web::Application->new(
		manifest => {
			name => 'test application',
			short_name => 'test',
			start_url => '/',
			icons => {
				file => 't/resources/320x320-icon.png',
				outpath => 't/resources/icons'
			},
			display => 'standalone',
			background_color => '#dadada',
			theme_color => '#dadada'
		}
	));
	my $expected = {
		'background_color' => '#dadada',
		'display' => 'standalone',
		'icons' => [
			{
				'sizes' => '310x310',
				'src' => '/t/resources/icons/310x310-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '192x192',
				'src' => '/t/resources/icons/192x192-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '180x180',
				'src' => '/t/resources/icons/180x180-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '152x152',
				'src' => '/t/resources/icons/152x152-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '150x150',
				'src' => '/t/resources/icons/150x150-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '144x144',
				'src' => '/t/resources/icons/144x144-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '128x128',
				'src' => '/t/resources/icons/128x128-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '120x120',
				'src' => '/t/resources/icons/120x120-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '114x114',
				'src' => '/t/resources/icons/114x114-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '96x96',
				'src' => '/t/resources/icons/96x96-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '76x76',
				'src' => '/t/resources/icons/76x76-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '72x72',
				'src' => '/t/resources/icons/72x72-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '70x70',
				'src' => '/t/resources/icons/70x70-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '60x60',
				'src' => '/t/resources/icons/60x60-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '57x57',
				'src' => '/t/resources/icons/57x57-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '48x48',
				'src' => '/t/resources/icons/48x48-icon.png',
				'type' => 'image/png'
			},
			{
				'sizes' => '36x36',
				'src' => '/t/resources/icons/36x36-icon.png',
				'type' => 'image/png'
			}
		],
		'name' => 'test application',
		'short_name' => 'test',
		'start_url' => '/',
		'theme_color' => '#dadada'
	};
	is_deeply($pwa->manifest, $expected, 'generate icons on new');
	ok(my $remove = $pwa->tools->{remove_directory}->('t/resources/icons'));
};

done_testing();
