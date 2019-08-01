package Progressive::Web::Application::Template::PreCacheEndpoint;

use parent 'Progressive::Web::Application::Template::Base';

sub required_params { qw/cache_name offline_path precache_endpoint/ }

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
var precache_endpoint = {precache_endpoint};

self.addEventListener('install', function (e) {
	e.waitUntil(
		caches.open(cacheName).then(function(cache) {i
			fetch(precache_endpoint).then(function(response) {
				// expects a JSON encode ARRAY of resource/endpoint urls
				return response.json();
			}).then(function(urls) {
				cache.add(offlineFile);
				return cache.addAll(urls);
			});
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
		caches.open(cacheName).then(function(cache) {
			return cache.match(e.request).then(function (response) {
				return response || fetch(e.request).catch(function () {
					return caches.match(offlineFile);
				});
			});
		});
	);
});

__END__
