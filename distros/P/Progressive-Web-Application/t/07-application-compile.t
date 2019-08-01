use Test::More;
use lib '.';
use Progressive::Web::Application;
subtest compile-error-no_root_set => sub {
	plan tests => 3;
	ok(my $pwa = Progressive::Web::Application->new(
		params => {
			files_to_cache => [
				qw/b c d/
			],
			offline_path => 'a',
			cache_name => 'my-cache-name'
		}
	), 'new with files_to_cache, cache_name and offline_path');
	is(eval {
		$pwa->compile();
	}, undef, 'errors');
	like(
		$@, 
		qr/No root directory provided to compile manifest and service worker/,
		'No root directory provided to compile manifest and service worker'
	);
};

subtest compile-only_manifest-root_new => sub {
	plan tests => 5;
	ok(my $pwa = Progressive::Web::Application->new(
		root => 't/',
		manifest => {
			name => 'test application',
			short_name => 'test',
			start_url => '/',
			icons => 't/resources',
			display => 'standalone',
			background_color => '#dadada',
			theme_color => '#dadada'
		}
	), 'pwa manifest new');
	ok(!$pwa->compile(), 'compile');
	ok(my $manifest = $pwa->tools->{from_json}->($pwa->tools->{read_file}->('t/manifest.json')), 'retrieve compiled manifest' );
	is_deeply($manifest, $pwa->tools->{from_json}->('{
   "short_name" : "test",
   "display" : "standalone",
   "theme_color" : "#dadada",
   "start_url" : "/",
   "icons" : [
      {
         "src" : "/resources/36x36-icon.png",
         "type" : "image/png",
         "sizes" : "36x36"
      },
      {
         "src" : "/resources/320x320-icon.png",
         "type" : "image/png",
         "sizes" : "310x310"
      }
   ],
   "background_color" : "#dadada",
   "name" : "test application"
}
'), 'manifest matches');
	ok($pwa->tools->{remove_file}->('t/manifest.json'), 'remove manifest.json');
};

subtest compile-only_manifest-root_passed => sub {
	plan tests => 5;
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
	), 'pwa manifest new');
	ok(!$pwa->compile('t/'), 'compile');
	ok(my $manifest = $pwa->tools->{from_json}->($pwa->tools->{read_file}->('t/manifest.json')), 'retrieve compiled manifest' );
	is_deeply($manifest, $pwa->tools->{from_json}->('{
   "short_name" : "test",
   "display" : "standalone",
   "theme_color" : "#dadada",
   "start_url" : "/",
   "icons" : [
      {
         "src" : "/t/resources/36x36-icon.png",
         "type" : "image/png",
         "sizes" : "36x36"
      },
      {
         "src" : "/t/resources/320x320-icon.png",
         "type" : "image/png",
         "sizes" : "310x310"
      }
   ],
   "background_color" : "#dadada",
   "name" : "test application"
}
'), 'manifest matches');
	ok($pwa->tools->{remove_file}->('t/manifest.json'), 'remove manifest');
};

subtest compile-only_templates-root_templates => sub {
	plan tests => 5;
	ok(my $pwa = Progressive::Web::Application->new(
		root => 't/',
		params => {
			cache_name => 'test-cache-name',
			files_to_cache => [
				qw/b c d/
			],
			offline_path => 'a'
		}
	), 'new with files_to_cache and offline_path');
	ok(!$pwa->compile(), 'compile');
	my $tool = $pwa->tools();
	is(
		$tool->{read_file}->('t/pwa.js'), 
		$tool->{read_file}->('t/resources/pwa.js'), 
		'pwa.js rendered'
	);
	is(
		$tool->{read_file}->('t/service-worker.js'), 
		$tool->{read_file}->('t/resources/service-worker.js'), 
		'service-worker.js'
	);
	ok($tool->{remove_file}->('t/pwa.js') && $tool->{remove_file}->('t/service-worker.js'), 'remove temp directory');
};

subtest compile-only_templates-passed_templates => sub {
	plan tests => 5;
	ok(my $pwa = Progressive::Web::Application->new(
		params => {
			cache_name => 'test-cache-name',
			files_to_cache => [
				qw/b c d/
			],
			offline_path => 'a'
		}
	), 'new with files_to_cache and offline_path');
	ok(!$pwa->compile(
		't/',
	), 'compile');
	my $tool = $pwa->tools();
	is(
		$tool->{read_file}->('t/pwa.js'), 
		$tool->{read_file}->('t/resources/pwa.js'), 
		'pwa.js rendered'
	);
	is(
		$tool->{read_file}->('t/service-worker.js'), 
		$tool->{read_file}->('t/resources/service-worker.js'), 
		'service-worker.js'
	);
	ok($pwa->tools->{remove_file}->('t/pwa.js') && $pwa->tools->{remove_file}->('t/service-worker.js'), 'remove temp directory');
};

done_testing();
