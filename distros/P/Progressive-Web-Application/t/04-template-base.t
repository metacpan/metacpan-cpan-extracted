package main;
use lib '.';
use Test::More;
use Progressive::Web::Application::Template::Base;
use Progressive::Web::Application::Template::General;

subtest empty_new => sub {
	plan tests => 1;
	ok(Progressive::Web::Application::Template::Base->new());
};

subtest get_data_section => sub {
	ok(my $pwa = Progressive::Web::Application::Template::General->new());
	ok(1);
};

subtest required_params => sub {
	plan tests => 2;
	ok(my $pwa = Progressive::Web::Application::Template::General->new());
	is_deeply([$pwa->required_params()], [qw/cache_name files_to_cache offline_path/]);
};

subtest render => sub {
	plan tests => 3;
	ok(my $pwa = Progressive::Web::Application::Template::General->new());
	ok(my $templates = $pwa->render({
		cache_name => '', 
		files_to_cache => '', 
		offline_path => '' 
	}));
	is($templates->{'pwa.js'}, 'if (\'serviceWorker\' in navigator) {
	navigator.serviceWorker.getRegistrations().then(function (registrations) {
		navigator.serviceWorker.register(\'/service-worker.js\').then(function (worker) {
			console.log(\'Service Worker Registered\');
		});
	});
}', 'okay quick render true');
};

done_testing();


