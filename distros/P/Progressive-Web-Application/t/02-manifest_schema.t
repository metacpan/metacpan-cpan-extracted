use Test::More;
use lib '.';
use Progressive::Web::Application;
my $manifest = Progressive::Web::Application->manifest_schema();

subtest name => sub {
	plan tests => 3;
	is($manifest->{name}->('test okay', 'test okay'), 'test okay', 'name true');
	is(eval{$manifest->{name}->({okay => 'no'}, 'custom')}, undef, 'name errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest short_name => sub {
	plan tests => 3;
	is($manifest->{short_name}->('test okay', 'test okay'), 'test okay', 'name true');
	is(eval{$manifest->{short_name}->({okay => 'no'}, 'custom')}, undef, 'name errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest start_url => sub {
	plan tests => 3;
	is($manifest->{start_url}->('/okay/path', 'test okay'), '/okay/path', 'start_url true');
	is(eval{$manifest->{start_url}->({okay => 'no'}, 'custom')}, undef, 'name errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest icons => sub {
	plan tests => 3;
	my $icons = $manifest->{icons}->('t/resources');
	my @expected = (
		{
			sizes => '36x36',
			src => '/t/resources/36x36-icon.png',
			type => 'image/png'
		},
		{
			sizes => '310x310',
			src => '/t/resources/320x320-icon.png',
			type => 'image/png'
		}
	);

	is_deeply($icons, \@expected, 'icons string (directory) true');

	my $new = {
		sizes => '128x128',
		src => 't/unkown_path/128x128-icon.png',
		type => 'image/png'
	};
	$icons = $manifest->{icons}->([ 't/resources', $new ]);
	is_deeply($icons, [@expected, $new], 'icons array (directory, hash) true');


	my $code = sub {
		my $ex =  {
			sizes => '152x152',
			src => '/t/unkown_path/152x152-icon.png',
			type => 'image/png'
		};
		push @expected, $ex;
		return $ex;
	};
	$icons = $manifest->{icons}->([ 't/resources', $code, $new ]);
	is_deeply($icons, [@expected, $new], 'icons array (directory, code, hash) true');
		
};

subtest display => sub {
	plan tests => 5;
	is($manifest->{display}->('standalone', 'standalone'), 'standalone', 'display true');
	is(eval{$manifest->{display}->({okay => 'no'})}, undef, 'display errors');
	like($@, qr/Value is not a scalar for field display/, 'Value is not a scalar for field display');
	is(eval{$manifest->{display}->('okay-no', 'custom')}, undef, 'display errors');
	like($@, qr/Invalid display value passed okay-no must be one of standalone, minimal-ui, fullscreen or browser/, 'Invalid display value passed okay-no must be one of standalone, minimal-ui, fullscreen or browser');
};

subtest background_color => sub {
	plan tests => 3;
	is($manifest->{background_color}->('#DADADA', 'background_colour'), '#dadada', 'background_colour true');
	is(eval{ $manifest->{background_color}->('abcdefhji', 'background_colour') }, undef, 'background_colour error');
	like($@, qr/Cannot convert the colour format/, 'Cannot convert the colour format');
};

subtest theme_color => sub {
	plan tests => 3;
	is($manifest->{theme_color}->('#DADADA', 'theme_color'), '#dadada', 'theme_color true');
	is(eval{ $manifest->{theme_color}->('abcdefhji', 'theme_color') }, undef, 'theme_color error');
	like($@, qr/Cannot convert the colour format/, 'Cannot convert the colour format');
};

subtest lang => sub {
	plan tests => 3;
	is($manifest->{lang}->('en-GB', 'test okay'), 'en-GB', 'lang true');
	is(eval{$manifest->{lang}->({okay => 'no'}, 'custom')}, undef, 'lang errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest dir => sub {
	plan tests => 3;
	is($manifest->{dir}->('auto', 'test okay'), 'auto', 'dir true');
	is(eval{$manifest->{dir}->({okay => 'no'}, 'custom')}, undef, 'dir errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest orientation => sub {
	plan tests => 5;
	is($manifest->{orientation}->('any', 'test okay'), 'any', 'orientation true');
	is(eval{$manifest->{orientation}->({okay => 'no'}, 'custom')}, undef, 'orientation errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
	is(eval{$manifest->{orientation}->('nope', 'custom')}, undef, 'orientation errors');
	like($@, qr/Invalid orientation value passed nope/, 'Invalid orientation value passed nope');
};

subtest prefer_related_applications => sub {
	plan tests => 4;
	is_deeply($manifest->{prefer_related_applications}->(\1, 'test okay'), \1, 'prefer_related_applications true');
	is_deeply($manifest->{prefer_related_applications}->(\0, 'test okay'), \0, 'prefer_related_applications true');
	is(eval{$manifest->{prefer_related_applications}->({okay => 'no'}, 'custom')}, undef, 'prefer_related_applications errors');
	like($@, qr/Not a SCALAR/, 'Value is not a scalar for field custom');
};

subtest related_applications => sub {
	plan tests => 8;
	my $app = {
		platform => "play", 
		url => "https://play.google.com/store/apps/details?id=com.example.app1", 
		id => "com.example.app1"
	};
	is_deeply($manifest->{related_applications}->([$app], 'test okay'), [$app], 'related_applications true');
	is(eval{$manifest->{related_applications}->({okay => 'no'}, 'custom')}, undef, 'related_applications  errors');
	like($@, qr/Value is not an ARRAY for field custom/, 'Value is not an array for field custom');
	delete $app->{platform};
	is(eval{$manifest->{related_applications}->([$app], 'custom')}, undef, 'related_applications errors');
	like($@, qr/Missing required param platform/, 'Missing required param platform');
	is(eval{$manifest->{related_applications}->([sub{$app}], 'custom')}, undef, 'related_applications errors');
	like($@, qr/related_applicaiton is not a HASH/, 'related_applicaiton is not a HASH');
	my $original = $Progressive::Web::Application::TOOL{to_json};
	$Progressive::Web::Application::TOOL{to_json} = sub {die 'dead'};
	is(eval{$manifest->{related_applications}->([$app], 'custom')}, undef, 'ummmmm');
	$Progressive::Web::Application::TOOL{to_json} = $original;
};

subtest iarc_rating_id => sub {
	plan tests => 3;
	is($manifest->{iarc_rating_id}->('TODO-parenting', 'test okay'), 'TODO-parenting', 'iarc_rating_id true');
	is(eval{$manifest->{iarc_rating_id}->({okay => 'no'}, 'custom')}, undef, 'iarc_rating_id errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest iarc_rating_id => sub {
	plan tests => 3;
	is($manifest->{iarc_rating_id}->('TODO-parenting', 'test okay'), 'TODO-parenting', 'iarc_rating_id true');
	is(eval{$manifest->{iarc_rating_id}->({okay => 'no'}, 'custom')}, undef, 'iarc_rating_id errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest scope => sub {
	plan tests => 3;
	is($manifest->{scope}->('/some/scope', 'test okay'), '/some/scope', 'scope true');
	is(eval{$manifest->{scope}->({okay => 'no'}, 'custom')}, undef, 'scope errors');
	like($@, qr/Value is not a scalar for field custom/, 'Value is not a scalar for field custom');
};

subtest screenshots => sub {
	plan tests => 5;
	my $shot = {
		src => "screenshot1.webp",
		sizes => "1280x720",
		type => "image/webp"
	};
	is_deeply($manifest->{screenshots}->([$shot], 'test okay'), [$shot], 'screenshots true');
	is(eval{$manifest->{screenshots}->({okay => 'no'}, 'custom')}, undef, 'screenshots  errors');
	like($@, qr/Value is not an ARRAY for field custom/, 'Value is not an array for field custom');
	delete $shot->{src};
	is(eval{$manifest->{screenshots}->([$shot], 'custom')}, undef, 'screenshots errors');
	like($@, qr/Missing required param src/, 'Missing required param src');
};

subtest categories => sub {
	plan tests => 3;
	is_deeply($manifest->{categories}->(['OpenSource'], 'test okay'), ['OpenSource'], 'scope true');
	is(eval{$manifest->{categories}->({okay => 'no'}, 'custom')}, undef, 'scope errors');
	like($@, qr/Value is not an ARRAY for field custom/, 'Value is not a scalar for field custom');
};

done_testing();
