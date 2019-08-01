package Progressive::Web::Application::Template::OfflineOnly;

use parent 'Progressive::Web::Application::Template::Base';

sub required_params { qw/cache_name offline_path/ }

1;

__DATA__

@@ pwa.js

if ('serviceWorker' in navigator) {
	navigator.serviceWorker.getRegistrations().then(function (registrations) {
		navigator.serviceWorker.register('/service-worker.js').then(function (worker) {
			console.log('Service Worker Registered');
		});
	});
}

@@ service-worker.js

var cacheName = {cache_name};
var offlineFile = {offline_path};

self.addEventListener('install', function (e) {
	e.waitUntil(
		caches.open(cacheName).then(function(cache) {
			return cache.add(offlineFile);
	     	})
	);
});

self.addEventListener('activate', function (e) {
	e.waitUntil(
		caches.keys().then(function(keyList) {
			return Promise.all(
				keyList.filter(function(cacheName) {}).map(function(key) {
					return caches.delete(key);
				})
			);
		})
	);
	return self.clients.claim();
});

self.addEventListener('fetch', function (e) {
	e.waitUntil(
		fetch(e.request).catch(function () {
			caches.match(offlineFile).then(function (response) {
				return response;
			});
		});
	);
});

__END__
