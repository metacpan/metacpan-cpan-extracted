use Test::More;
use lib '.';

use Progressive::Web::Application;
my $tool = Progressive::Web::Application->tools();

subtest scalar_check => sub {
	plan tests => 3;
	is($tool->{scalar_check}->('okay', 'custom'), 'okay', 'scalar_check true');
	is(eval{$tool->{scalar_check}->({okay => 'no'}, 'custom')}, undef, 'scalar_check errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest array_check => sub {
	plan tests => 3;
	is_deeply($tool->{array_check}->(['okay'], 'custom'), ['okay'], 'array_check true');
	is(eval{$tool->{array_check}->('no', 'custom')}, undef, 'array_check errors');
	like($@, qr/Value is not an ARRAY for field custom/, 'Value is not a scalar for field custom');
};

subtest colour_check => sub {
	plan tests => 3;
	is($tool->{colour_check}->('#dadada', 'custom'), '#dadada', 'colour_check true');
	is(eval{$tool->{colour_check}->({okay => 'no'}, 'custom')}, undef, 'scalar_check errors');
	like($@, qr/Cannot convert the colour format/, 'Cannot convert the colour format');
};

subtest to_json => sub {
	is($tool->{to_json}->({okay=>\1}), '{
   "okay" : true
}
', 'toJSON true');
	is(eval{$tool->{to_json}->(\"okay no", 'custom')}, undef, 'scalar_check errors');
	like($@, qr/cannot encode reference to scalar/, 'cannot encode reference to scalar');
};

subtest from_json => sub {
	plan tests => 3;
	is_deeply($tool->{from_json}->('{"okay":true}', 'custom'), { okay => \1 }, 'from_json true');
	is(eval{$tool->{colour_check}->({okay => 'no'}, 'custom')}, undef, 'scalar_check errors');
	like($@, qr/Cannot convert the colour format/, 'Cannot convert the colour format');
};

subtest write_file => sub {
	plan tests => 3;
	my $file = 't/resources/test.txt';
	ok($tool->{write_file}->($file, 'some text'));
	is(eval{$tool->{write_file}->('t/resources/restricted/thing.txt', 'kaput')}, undef, 'Cannot write file');
	like($@, qr/Cannot open file for writing No such file or directory/, 'Cannot open file for writing No such file or directory');
};

subtest read_file => sub {
	plan tests => 3;
	my $file = 't/resources/test.txt';
	my $text = $tool->{read_file}->($file);
	is($text, 'some text', 'read_file true');
	is(eval{$tool->{read_file}->('t/resources/restricted/thing.txt', 'kaput')}, undef, 'Cannot read file');
	like($@, qr/Cannot open file for reading No such file or directory/, 'Cannot open file for reading No such file or directory');
};

subtest remove_file => sub {
	plan tests => 3;
	my $file = 't/resources/test.txt';
	my $delete = $tool->{remove_file}->($file);
	is($delete, 1, 'delete_file true');
	is(eval{$tool->{remove_file}->('t/resources/restricted/thing.txt', 'kaput')}, undef, 'Cannot remove file');
	like($@, qr/Cannot remove file/, 'Cannot remove file');
};

subtest generate_icons => sub {
	plan tests => 4;
	my @files = $tool->{generate_icons}->(
		't/resources/320x320-icon.png',
		outpath => 't/resources/icons',
		icon_name => 'icon'
	);
	is_deeply(\@files, [
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
	'generate_icons true');
	is(eval{ $tool->{generate_icons}->() }, undef, 'no icon passed');
	like($@, qr/No initial icon passed/, 'No initial icon passed');
	@files = $tool->{generate_icons}->(
		't/resources/icons/310x310-icon.png',
	);
	is_deeply(\@files, [
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
	'generate_icons true');


};

subtest read_directory => sub {
	plan tests => 6;
	my @files = $tool->{read_directory}->('t/resources/icons');
 	is_deeply(scalar @files, 17, 'read_directory true');
	@files = $tool->{read_directory}->('t/resources/icons', 
		blacklist_regex => qr/36x36/
	);
	is_deeply(scalar @files, 16, 'read_directory with blacklist_regex true');
	@files = $tool->{read_directory}->('t/resources', 
		whitelist_regex => qr/36x36/,
		recurse => 1
	);
	is_deeply(scalar @files, 1, 'read_directory with blacklist_regex true');
	@files = $tool->{read_directory}->('t/resources', 
		recurse => 1,
		whitelist_regex => 'icons'
	);
	is_deeply(scalar @files, 17, 'read_directory with blacklist_regex true');
	is(eval{$tool->{read_directory}->('t/resources/restricted/thing.txt')}, undef, 'Cannot read file');
	like($@, qr/Can't open/, q|Can't open directory|);
};

subtest remove_directory => sub {
	plan tests => 1;
	my $remove = $tool->{remove_directory}->('t/resources/icons');
	is_deeply($remove, 1, 'remove_directory true');
};

subtest identify_icon_size => sub {
	plan tests => 2;
	my $size = $tool->{identify_icon_size}->('t/resources/36x36-icon.png');
	is($size, '36x36', 'identify_icon_size true');
	is($tool->{identify_icon_size}->('t/resources/kaput.png'), undef, 'invalid icon size');
};

subtest identify_icon_information => sub {
	plan tests => 1;
	my @icons = $tool->{identify_icon_information}->(
		'',
		sort { $b cmp $a } $tool->{read_directory}->('t/resources')
	);
	is_deeply(\@icons, [
		{
			'sizes' => '36x36',
			'src' => '/t/resources/36x36-icon.png',
			'type' => 'image/png'
		},
		{
			'sizes' => '310x310',
			'src' => '/t/resources/320x320-icon.png',
			'type' => 'image/png'
		}
	], 'identify_icon_infromation true');

};

subtest validate_icon_information => sub {
	plan tests => 3;
	my $icon = {
		sizes => '310x310',
		src => 't/resources/t/resources/320x320-icon.png',
		type => 'image/png'
	};
	is_deeply( $tool->{validate_icon_information}->($icon), {
		sizes => '310x310',
		src => '/t/resources/t/resources/320x320-icon.png',
		type => 'image/png'	
	}, 'validate_icon_information true');
	$icon->{sizes} = '320x320';
	is(eval {$tool->{validate_icon_information}->($icon)}, undef, 'validate_icon_infomation error');
	like($@, qr/Invalid size 320x320 for/, 'Invalid size 320x320 for');
};

subtest identify_files_to_cache => sub {
	my @icons = $tool->{identify_files_to_cache}->(
		't/resources/things',
	);
	is_deeply(\@icons, [
		'/t/resources/things/one.js',
		'/t/resources/things/two.js',
	], 'identify_files_to_cache true');
	my @icons = $tool->{identify_files_to_cache}->(
		't/resources/things',
		root => 't/'
	);
	is_deeply(\@icons, [
		'/resources/things/one.js',
		'/resources/things/two.js',
	], 'identify_files_to_Cache root true');
	my @icons = $tool->{identify_files_to_cache}->(
		't/resources/things',
		root => 't/',
		pathpart => 'payment'
	);
	is_deeply(\@icons, [
		'/payment/resources/things/one.js',
		'/payment/resources/things/two.js',
	], 'identify_files_to_cache root+pathpart true');

	is(eval{ $tool->{identify_files_to_cache}->() }, undef, 'no directory passed');
	like($@, qr/no directory passed into identify_files_to_cache/, 'no directory passed into identify_files_to_cache');
};

done_testing();
