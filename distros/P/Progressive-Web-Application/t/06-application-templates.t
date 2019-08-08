use Test::More;
use lib '.';
use Progressive::Web::Application;

subtest templates => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application->new(
		template => 'General',
		params => {
			files_to_cache => [
				qw/b c d/
			],
			offline_path => 'a',
			cache_name => 'my-cache-name'
		}
	), 'new with files_to_cache and offline_path');
	is_deeply(
		[sort( keys %{$pwa->templates()})],	
		['pwa.js', 'service-worker.js'],
		'instantiate with params files_to_cache and offline_path'
	);
};

subtest template => sub {
	plan tests => 2;
	ok (my $pwa = Progressive::Web::Application->new(), 'instantiate a new pwa object');
	is (ref $pwa->template(), 'Progressive::Web::Application::Template::General', 'we have an template object');
};

done_testing();
