if ('serviceWorker' in navigator) {
	navigator.serviceWorker.getRegistrations().then(function (registrations) {
		navigator.serviceWorker.register('/service-worker.js').then(function (worker) {
			console.log('Service Worker Registered');
		});
	});
}