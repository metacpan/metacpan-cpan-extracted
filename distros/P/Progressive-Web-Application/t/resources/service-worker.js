var cacheName = "test-cache-name";
var filesToCache = [
   "a",
   "b",
   "c",
   "d"
];
var offlineFile = "a";

self.addEventListener('install', function (e) {
	e.waitUntil(
		caches.open(cacheName).then(function(cache) {
			return cache.addAll(filesToCache);
	     	})
	);
});

self.addEventListener('activate', function (e) {
	e.waitUntil(
		caches.keys().then(function (keyList) {
			return Promise.all(keyList.map(function(key) {
				if (key !== cacheName) {
					return caches.delete(key);
				}
			}));
		})
	);
	return self.clients.claim();
});

self.addEventListener('fetch', function (e) {
	var requestURL = e.request.url;
	if (filesToCache.indexOf(requestURL) > 1) {
		e.respondWith(
			caches.match(e.request).then(function(response) {
				return response || fetch(e.request).catch(function () {
						caches.match(offlineFile).then(function (response) {
							return response;
						});
				});
			})
		);
	} else {
		var requestWith = e.request.headers.get('X-Requested-With');
		var htmlResponse = ! requestURL.match(/\.(?!html)([a-zA-Z]+)$/);
		e.respondWith(
			caches.open(cacheName).then(function(cache) {
				return fetch(e.request).then(function(response) {
					cache.put(e.request, response.clone());
					return response;
				});
			}).catch(function() {
				return caches.match(e.request).then(function(response) {
					return response ? response.clone() : requestWith === 'XMLHttpRequest' ? new Response(JSON.stringify({
						error: "Network issues, try again when you're back online"
					})) : htmlResponse ? caches.match(offlineFile) : new Response();
				});
			})
		);
	}
});
