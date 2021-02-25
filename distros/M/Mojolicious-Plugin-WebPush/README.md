# NAME

Mojolicious::Plugin::WebPush - plugin to aid real-time web push

# SYNOPSIS

    # Mojolicious::Lite
    my $sw = plugin 'ServiceWorker' => { debug => 1 };
    my $webpush = plugin 'WebPush' => {
      save_endpoint => '/api/savesubs',
      subs_session2user_p => \&subs_session2user_p,
      subs_create_p => \&subs_create_p,
      subs_read_p => \&subs_read_p,
      subs_delete_p => \&subs_delete_p,
      ecc_private_key => 'vapid_private_key.pem',
      claim_sub => "mailto:admin@example.com",
    };

    sub subs_session2user_p {
      my ($c, $session) = @_;
      return Mojo::Promise->reject("Session not logged in") if !$session->{user_id};
      Mojo::Promise->resolve($session->{user_id});
    }

    sub subs_create_p {
      my ($c, $session, $subs_info) = @_;
      app->db->save_subs_p($session->{user_id}, $subs_info);
    }

    sub subs_read_p {
      my ($c, $user_id) = @_;
      app->db->lookup_subs_p($user_id);
    }

    sub subs_delete_p {
      my ($c, $user_id) = @_;
      app->db->delete_subs_p($user_id);
    }

# DESCRIPTION

[Mojolicious::Plugin::WebPush](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebPush) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin. In
order to function, your app needs to have first installed
[Mojolicious::Plugin::ServiceWorker](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AServiceWorker) as shown in the synopsis above.

# METHODS

[Mojolicious::Plugin::WebPush](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AWebPush) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious%3A%3APlugin) and implements the following new ones.

## register

    my $p = $plugin->register(Mojolicious->new, \%conf);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application, returning the plugin
object. Takes a hash-ref as configuration, see ["OPTIONS"](#options) for keys.

# OPTIONS

## save\_endpoint

Required. The route to be added to the app for the service worker to
register users for push notification. The handler for that will call
the ["subs\_create\_p"](#subs_create_p). If success is indicated, it will return JSON:

    { "data": { "success": true } }

If failure:

    { "errors": [ { "message": "The exception reason" } ] }

This will be handled by the provided service worker. In case it is
required by the app itself, the added route is named `webpush.save`.

## subs\_session2user\_p

Required. The code to be called to look up the user currently identified
by this session, which returns a promise of the user ID. Must reject
if no user logged in and that matters. It will be passed parameters:

- The ["session" in Mojolicious::Controller](https://metacpan.org/pod/Mojolicious%3A%3AController#session) object, to correctly identify
the user.

## subs\_create\_p

Required. The code to be called to store users registered for push
notifications, which must return a promise of a true value if the
operation succeeds, or reject with a reason. It will be passed parameters:

- The ID to correctly identify the user. Please note that you ought to
allow one person to have several devices with web-push enabled, and to
design accordingly.
- The `subscription_info` hash-ref, needed to push actual messages.

## subs\_read\_p

Required. The code to be called to look up a user registered for push
notifications. It will be passed parameters:

- The opaque information your app uses to identify the user.

Returns a promise of the `subscription_info` hash-ref. Must reject if
not found.

## subs\_delete\_p

Required. The code to be called to delete up a user registered for push
notifications. It will be passed parameters:

- The opaque information your app uses to identify the user.

Returns a promise of the deletion result. Must reject if not found.

## ecc\_private\_key

A value to be passed to ["new" in Crypt::PK::ECC](https://metacpan.org/pod/Crypt%3A%3APK%3A%3AECC#new): a simple scalar is a
filename, a scalar-ref is the actual key. If not provided,
["webpush.authorization"](#webpush-authorization) will (obviously) not be able to function.

## claim\_sub

A value to be used as the `sub` claim by the ["webpush.authorization"](#webpush-authorization),
which needs it. Must be either an HTTPS or `mailto:` URL.

## claim\_exp\_offset

A value to be added to current time, in seconds, in the `exp` claim
for ["webpush.authorization"](#webpush-authorization). Defaults to 86400 (24 hours). The maximum
valid value in RFC 8292 is 86400.

## push\_handler

Override the default push-event handler supplied to
["add\_event\_listener" in Mojolicious::Plugin::ServiceWorker](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AServiceWorker#add_event_listener). The default
will interpret the message as a JSON object. The key `title` will be
the notification title, deleted from that object, then the object will be
the options passed to `<ServiceWorkerRegistration>.showNotification`.

See
[https://developers.google.com/web/fundamentals/push-notifications/handling-messages](https://developers.google.com/web/fundamentals/push-notifications/handling-messages)
for possibilities.

# HELPERS

## webpush.create\_p

    $c->webpush->create_p($user_id, $subs_info)->then(sub {
      $c->render(json => { data => { success => \1 } });
    });

## webpush.read\_p

    $c->webpush->read_p($user_id)->then(sub {
      $c->render(text => 'Info: ' . to_json(shift));
    });

## webpush.delete\_p

    $c->webpush->delete_p($user_id)->then(sub {
      $c->render(json => { data => { success => \1 } });
    });

## webpush.authorization

    my $header_value = $c->webpush->authorization($subs_info);

Won't function without ["claim\_sub"](#claim_sub) and ["ecc\_private\_key"](#ecc_private_key), or
`$subs_info` having a valid URL to get the base of as the `aud`
claim. Returns a suitable `Authorization` header value to send to
a push service.  Valid for a period defined by ["claim\_exp\_offset"](#claim_exp_offset).
but could become so to avoid unnecessary computation.

## webpush.public\_key

    my $pkey = $c->webpush->public_key;

Gives the app's public VAPID key, calculated from the private key.

## webpush.verify\_token

    my $bool = $c->webpush->verify_token($authorization_header_value);

Cryptographically verifies a JSON Web Token (JWT), such as generated
by ["webpush.authorization"](#webpush-authorization).

## webpush.encrypt

    use MIME::Base64 qw(decode_base64url);
    my $ciphertext = $c->webpush->encrypt($data_bytes,
      map decode_base64url($_), @{$subscription_info->{keys}}{qw(p256dh auth)}
    );

Returns the data encrypted according to RFC 8188, for the relevant
subscriber.

## webpush.send\_p

    my $result_p = $c->webpush->send_p($jsonable_data, $user_id, $ttl, $urgency);

JSON-encodes the given value, encrypts it according to the given user's
subscription data, adds a VAPID `Authorization` header, then sends it
to the relevant web-push endpoint.

Returns a promise of the result, which will be a hash-ref with either a
`data` key indicating success, or an `errors` key for an array-ref of
hash-refs with a `message` giving reasons.

If the sending gets a status code of 404 or 410, this indicates the
subscriber has unsubscribed, and ["webpush.delete\_p"](#webpush-delete_p) will be used to
remove the registration. This is considered success.

The `urgency` must be one of `very-low`, `low`, `normal` (the default)
or `high`. The `ttl` defaults to 30 seconds.

# TEMPLATES

Various templates are available for including in the app's templates:

## webpush-askPermission.html.ep

JavaScript functions, also for putting inside a `script` element:

- askPermission
- subscribeUserToPush
- sendSubscriptionToBackEnd

These each return a promise, and should be chained together:

    <button onclick="
      askPermission().then(subscribeUserToPush).then(sendSubscriptionToBackEnd)
    ">
      Ask permission
    </button>
    <script>
    %= include 'serviceworker-install'
    %= include 'webpush-askPermission'
    </script>

Each application must decide when to ask such permission, bearing in
mind that once permission is refused, it is very difficult for the user
to change such a refusal.

When it is granted, the JavaScript code will communicate with the
application, registering the needed information needed to web-push.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious%3A%3AGuides), [https://mojolicious.org](https://mojolicious.org).

[Mojolicious::Command::webpush](https://metacpan.org/pod/Mojolicious%3A%3ACommand%3A%3Awebpush) - command-line control of web-push.

RFC 8292 - Voluntary Application Server Identification (for web push).

[Crypt::RFC8188](https://metacpan.org/pod/Crypt%3A%3ARFC8188) - Encrypted Content-Encoding for HTTP (using `aes128gcm`).

[https://developers.google.com/web/fundamentals/push-notifications](https://developers.google.com/web/fundamentals/push-notifications)

# ACKNOWLEDGEMENTS

Part of this code is ported from
[https://github.com/web-push-libs/pywebpush](https://github.com/web-push-libs/pywebpush).
