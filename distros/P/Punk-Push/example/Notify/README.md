# Notify - Web Push on Punk

The example application for
[Punk::Push](https://metacpan.org/pod/Punk::Plugin::Push). Generated with
`punk new Notify` and then given push notifications.

```
perl bin/seed.pl            # a database, one user, and a VAPID keypair
set -a; . var/vapid.env; set +a
plackup app.psgi
prove -l t/
```

Then open <http://localhost:5000/>, sign in as `demo@example.com` / `demo`,
and press **Enable notifications**.

`app.psgi` and `t/01-basic.t` add the distribution's `blib` to `@INC` so the
demo runs before `Punk::Push` is installed. Drop those lines once it is.

## What to look at

**The keys are configuration.** `bin/seed.pl` writes a pair to
`var/vapid.env` once, and the application reads them from the environment. It
does not generate them at boot, because Hyperman runs a pool: a key minted per
process would differ per worker and per restart, and every subscription made
against the old one would be undeliverable in silence. `punk push keys` prints
a pair for a real deployment.

**Subscribing needs a user.** A subscription belongs to somebody, so
`/push/subscribe` is guarded - an unauthenticated POST that writes one lets
anybody who can guess a user id register their own browser for that user's
notifications. That is why this demo carries a sign-in at all. `/push/key` is
not guarded; it is a public key.

**The model is inherited, not copied.** `lib/Notify/Model/PushSubscription.pm`
is four lines:

```perl
package Notify::Model::PushSubscription;
use parent 'Punk::Model::PushSubscription';
```

It inherits the table and all nine columns. It exists only so the model lives
in this application's namespace, where somebody would look for it. Delete it
and the plugin registers its own. To add a column, add `use Punk::Model;` and
declare it - the inherited ones stay, and a redeclared field keeps its
position so the column order does not shift. (Needs Punk 0.45.)

**Scope.** The worker is served from `/push/` but must control the whole
site, so the plugin sends `Service-Worker-Allowed: /` with it. Without that
header the browser refuses to register it at all.

**Why nothing happens, in order.** Push needs a secure context: `localhost`
counts, other plain-HTTP hosts do not. Permission must be requested from a
click, and once denied cannot be re-requested. A service worker must be
registered and activated - the application tab in devtools shows it.

**The send form carries the whole surface.** Everything a payload may hold -
`title`, `body`, `url`, `icon`, `badge`, `tag` - and everything one send may
override: `ttl`, `urgency`, `topic`. Blank fields are left out rather than
sent empty, since an `icon` of `""` is a broken image and a `topic` of `""`
would collapse every notification into one. The icon and badge it offers are
shipped in `root/static/`, so they resolve.

**Sending.** `/notify` calls `$c->push_send($user_id, {...})`, which fans out
over every subscription that user has and returns a result each. One dead
device does not stop the others, and the page prints every outcome including
the failures.

**A 410 means gone.** If a push service says a subscription is `404` or `410`
the row is deleted; anything else, a `5xx` included, leaves it alone.
Subscribe from a browser, then clear the site's data in that browser, then
send: the next send prunes the row.
