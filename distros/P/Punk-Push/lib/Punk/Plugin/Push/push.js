// Punk::Push - the browser half.
//
// The one piece worth shipping: applicationServerKey wants a Uint8Array, not
// the base64url string every server hands out, and urlBase64ToUint8Array is
// where people get it wrong. Everything else here is short enough to read.
//
// Funky-Frame's js/core/service-worker.js has a fuller implementation if you
// want lifecycle handling, update prompts and the rest.

function urlBase64ToUint8Array(base64url) {
    const padding = '='.repeat((4 - (base64url.length % 4)) % 4);
    const base64 = (base64url + padding).replace(/-/g, '+').replace(/_/g, '/');
    const raw = window.atob(base64);
    const out = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
}

export async function subscribe(options = {}) {
    const prefix = options.prefix || '/push';
    const scope  = options.scope  || '/';

    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        throw new Error('this browser has no Push API');
    }

    // Permission cannot be re-requested once denied, so ask only in response
    // to something the user did - a click, not page load.
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
        throw new Error('notification permission was ' + permission);
    }

    const registration = await navigator.serviceWorker.register(
        options.worker || prefix + '/push-sw.js', { scope });
    await navigator.serviceWorker.ready;

    const key = await (await fetch(prefix + '/key')).text();

    // userVisibleOnly is not optional in practice: Chrome refuses a
    // subscription without it.
    const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(key.trim()),
    });

    const res = await fetch(prefix + '/subscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify(subscription),
    });
    if (!res.ok) throw new Error('subscribe failed: ' + res.status);

    return subscription;
}

export async function unsubscribe(options = {}) {
    const prefix = options.prefix || '/push';
    const registration = await navigator.serviceWorker.getRegistration();
    if (!registration) return false;

    const subscription = await registration.pushManager.getSubscription();
    if (!subscription) return false;

    // Tell the server first. If the browser drops it and the POST then fails,
    // the row is left behind with no way to reach it - the server would go on
    // sending to an endpoint nobody is listening to until a 410 prunes it.
    await fetch(prefix + '/unsubscribe', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'same-origin',
        body: JSON.stringify({ endpoint: subscription.endpoint }),
    });

    return subscription.unsubscribe();
}

export async function current() {
    const registration = await navigator.serviceWorker.getRegistration();
    return registration ? registration.pushManager.getSubscription() : null;
}
