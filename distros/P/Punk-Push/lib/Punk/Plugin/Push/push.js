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

// Whether a subscription was made with the key this server is signing with.
// `options.applicationServerKey` is an ArrayBuffer, and a browser too old to
// report it is treated as a mismatch: replacing a subscription costs one
// round trip, keeping the wrong one costs every notification.
function sameKey(subscription, key) {
    const have = subscription.options && subscription.options.applicationServerKey;
    if (!have) { return false; }
    const mine = new Uint8Array(have);
    if (mine.length !== key.length) { return false; }
    for (let i = 0; i < mine.length; i++) {
        if (mine[i] !== key[i]) { return false; }
    }
    return true;
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
    const appKey = urlBase64ToUint8Array(key.trim());

    // A SUBSCRIPTION THIS BROWSER ALREADY HAS IS IN THE WAY.
    //
    // Chrome refuses to create a second one for the same scope and throws
    // InvalidStateError - "A subscription with a different
    // applicationServerKey already exists" - so a browser that subscribed
    // under an older VAPID key can never subscribe again, and the button
    // that says it failed is the only sign. Safari replaces it quietly,
    // which is why this looks like a Chrome bug and is not one.
    //
    // A matching one is kept and posted again, because the row on the
    // server may be the thing that is missing.
    let subscription = await registration.pushManager.getSubscription();
    if (subscription && !sameKey(subscription, appKey)) {
        await subscription.unsubscribe();
        subscription = null;
    }

    // userVisibleOnly is not optional in practice: Chrome refuses a
    // subscription without it.
    if (!subscription) {
        subscription = await registration.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: appKey,
        });
    }

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
    const reg = await activeRegistration();
    if (!reg) return false;

    const subscription = await reg.pushManager.getSubscription();
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

// The registration to ask about a subscription, once it is worth asking.
//
// getRegistration() answers with whatever exists RIGHT NOW, and that is
// undefined while a worker is still installing - which is the moment a page
// that registers the worker and then asks about it loads. The answer was
// "not subscribed" for somebody who was.
//
// `ready` is the wait for an ACTIVE worker, but it never resolves when there
// is nothing registered at all, so it is only awaited once a registration is
// known to exist. That is the difference between a slow answer and no answer.
async function activeRegistration() {
    if (!('serviceWorker' in navigator)) { return null; }
    const now = await navigator.serviceWorker.getRegistration();
    if (!now) { return null; }
    return now.active ? now : navigator.serviceWorker.ready;
}

export async function current() {
    const reg = await activeRegistration();
    return reg ? reg.pushManager.getSubscription() : null;
}
