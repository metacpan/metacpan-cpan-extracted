// Punk::Push - a minimal service worker.
//
// A service worker is a cache with a lifetime of its own: the browser keeps
// the one it has and updates it on its own schedule. Once an installed
// browser is asking for this URL you cannot simply stop serving it.
//
// So this is for getting a demo working. Past that, copy both files into your
// own tree, serve them yourself, and set assets => 0. There is also only ONE
// service worker per scope - if you already register one for offline support,
// merge the two handlers below into it rather than registering a second, or
// whichever registered last wins and the other quietly stops working.

self.addEventListener('push', (event) => {
    let payload = {};
    if (event.data) {
        try { payload = event.data.json(); }
        catch (e) { payload = { body: event.data.text() }; }
    }

    const title = payload.title || 'Notification';
    const options = {
        body: payload.body,
        icon: payload.icon,
        badge: payload.badge,
        tag: payload.tag,
        data: { url: payload.url || '/' },
    };

    // waitUntil, or the worker may be killed before the notification shows.
    event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const url = (event.notification.data && event.notification.data.url) || '/';

    event.waitUntil((async () => {
        const clientList = await self.clients.matchAll({
            type: 'window', includeUncontrolled: true,
        });
        // Focus a tab already on the site rather than opening a second one.
        for (const client of clientList) {
            if (client.url === url && 'focus' in client) return client.focus();
        }
        if (self.clients.openWindow) return self.clients.openWindow(url);
    })());
});
