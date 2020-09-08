package Mojolicious::Plugin::WebPush;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::JSON qw(decode_json encode_json);
use Crypt::PK::ECC;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Crypt::JWT qw(encode_jwt decode_jwt);
use Crypt::RFC8188 qw(ece_encrypt_aes128gcm);

our $VERSION = '0.03';

my @MANDATORY_CONF = qw(
  subs_session2user_p
  save_endpoint
  subs_create_p
  subs_read_p
  subs_delete_p
);
my @AUTH_CONF = qw(claim_sub ecc_private_key);
my $DEFAULT_PUSH_HANDLER = <<'EOF';
event => {
  var msg = event.data.json();
  var title = msg.title;
  delete msg.title;
  event.waitUntil(self.registration.showNotification(title, msg));
}
EOF

sub _decode {
  my ($bytes) = @_;
  my $body = eval { decode_json($bytes) };
  # conceal error info like versions from attackers
  return (0, "Malformed request") if $@;
  (1, $body);
}

sub _error {
  my ($c, $error) = @_;
  $c->render(status => 500, json => { errors => [ { message => $error } ] });
}

sub _make_route_handler {
  my ($subs_session2user_p, $subs_create_p) = @_;
  sub {
    my ($c) = @_;
    my ($decode_ok, $body) = _decode($c->req->body);
    return _error($c, $body) if !$decode_ok;
    eval { validate_subs_info($body) };
    return _error($c, $@) if $@;
    return $subs_session2user_p->($c->session)->then(
      sub { $subs_create_p->($_[0], $body) },
    )->then(
      sub { $c->render(json => { data => { success => \1 } }) },
      sub { _error($c, @_) },
    );
  };
}

sub _make_auth_helper {
  my ($app, $conf) = @_;
  my $exp_offset = $conf->{claim_exp_offset} || 86400;
  my $key = Crypt::PK::ECC->new($conf->{ecc_private_key});
  my $aud = $app->webpush->aud;
  my $claims_start = { aud => $aud, sub => $conf->{claim_sub} };
  my $pkey = encode_base64url $key->export_key_raw('public');
  $app->helper('webpush.public_key' => sub { $pkey });
  sub {
    my ($c) = @_;
    my $claims = { exp => time + $exp_offset, %$claims_start };
    my $token = encode_jwt key => $key, alg => 'ES256', payload => $claims;
    "vapid t=$token,k=$pkey";
  };
}

sub _aud_helper {
  $_[0]->ua->server->url->path(Mojo::Path->new->trailing_slash(0)).'';
}

sub _verify_helper {
  my ($app, $auth_header_value) = @_;
  (my $schema, $auth_header_value) = split ' ', $auth_header_value;
  return if $schema ne 'vapid';
  my %k2v = map split('=', $_), split ',', $auth_header_value;
  eval {
    my $key = Crypt::PK::ECC->new;
    $key->import_key_raw(decode_base64url($k2v{k}), 'P-256');
    decode_jwt token => $k2v{t}, key => $key, alg => 'ES256', verify_exp => 0;
  };
}

sub _encrypt_helper {
  my ($c, $plaintext, $receiver_key, $auth_key) = @_;
  die "Invalid p256dh key specified\n"
    if length($receiver_key) != 65 or $receiver_key !~ /^\x04/;
  my $onetime_key = Crypt::PK::ECC->new->generate_key('prime256v1');
  ece_encrypt_aes128gcm(
    $plaintext, (undef) x 2, $onetime_key, $receiver_key, $auth_key,
  );
}

sub _send_helper {
  my ($c, $message, $user_id, $ttl, $urgency) = @_;
  $ttl ||= 30;
  $urgency ||= 'normal';
  $c->webpush->read_p($user_id)->then(sub {
    my ($subs_info) = @_;
    my $body = $c->webpush->encrypt(
      encode_json($message),
      map decode_base64url($_), @{$subs_info->{keys}}{qw(p256dh auth)}
    );
    my $headers = {
      Authorization => $c->webpush->authorization,
      'Content-Length' => length($body),
      'Content-Encoding' => 'aes128gcm',
      TTL => $ttl,
      Urgency => $urgency,
    };
    $c->app->ua->post_p($subs_info->{endpoint}, $headers, $body);
  })->then(sub {
    my ($tx) = @_;
    return $c->webpush->delete_p($user_id)->then(sub {
      { data => { success => \1 } }
    }) if $tx->res->code == 404 or $tx->res->code == 410;
    return { errors => [ { message => $tx->res->body } ] }
      if $tx->res->code > 399;
    { data => { success => \1 } };
  }, sub {
    { errors => [ { message => $_[0] } ] }
  });
}

sub register {
  my ($self, $app, $conf) = @_;
  my @config_errors = grep !exists $conf->{$_}, @MANDATORY_CONF;
  die "Missing config keys @config_errors\n" if @config_errors;
  $app->helper('webpush.create_p' => sub {
    eval { validate_subs_info($_[2]) };
    return Mojo::Promise->reject($@) if $@;
    $conf->{subs_create_p}->(@_[1,2]);
  });
  $app->helper('webpush.read_p' => sub { $conf->{subs_read_p}->($_[1]) });
  $app->helper('webpush.delete_p' => sub { $conf->{subs_delete_p}->($_[1]) });
  $app->helper('webpush.aud' => \&_aud_helper);
  $app->helper('webpush.authorization' => (grep !$conf->{$_}, @AUTH_CONF)
    ? sub { die "Must provide @AUTH_CONF\n" }
    : _make_auth_helper($app, $conf)
  );
  $app->helper('webpush.verify_token' => \&_verify_helper);
  $app->helper('webpush.encrypt' => \&_encrypt_helper);
  $app->helper('webpush.send_p' => \&_send_helper);
  my $r = $app->routes;
  $r->post($conf->{save_endpoint} => _make_route_handler(
    @$conf{qw(subs_session2user_p subs_create_p)},
  ), 'webpush.save');
  push @{ $app->renderer->classes }, __PACKAGE__;
  $app->serviceworker->add_event_listener(
    push => $conf->{push_handler} || $DEFAULT_PUSH_HANDLER
  );
  $self;
}

sub validate_subs_info {
  my ($info) = @_;
  die "Expected object\n" if ref $info ne 'HASH';
  my @errors = map "no $_", grep !exists $info->{$_}, qw(keys endpoint);
  push @errors, map "no $_", grep !exists $info->{keys}{$_}, qw(auth p256dh);
  die "Errors found in subscription info: " . join(", ", @errors) . "\n"
    if @errors;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::WebPush - plugin to aid real-time web push

=head1 SYNOPSIS

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
    my ($session) = @_;
    return Mojo::Promise->reject("Session not logged in") if !$session->{user_id};
    Mojo::Promise->resolve($session->{user_id});
  }

  sub subs_create_p {
    my ($session, $subs_info) = @_;
    app->db->save_subs_p($session->{user_id}, $subs_info);
  }

  sub subs_read_p {
    my ($user_id) = @_;
    app->db->lookup_subs_p($user_id);
  }

  sub subs_delete_p {
    my ($user_id) = @_;
    app->db->delete_subs_p($user_id);
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::WebPush> is a L<Mojolicious> plugin. In
order to function, your app needs to have first installed
L<Mojolicious::Plugin::ServiceWorker> as shown in the synopsis above.

=head1 METHODS

L<Mojolicious::Plugin::WebPush> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  my $p = $plugin->register(Mojolicious->new, \%conf);

Register plugin in L<Mojolicious> application, returning the plugin
object. Takes a hash-ref as configuration, see L</OPTIONS> for keys.

=head1 OPTIONS

=head2 save_endpoint

Required. The route to be added to the app for the service worker to
register users for push notification. The handler for that will call
the L</subs_create_p>. If success is indicated, it will return JSON:

  { "data": { "success": true } }

If failure:

  { "errors": [ { "message": "The exception reason" } ] }

This will be handled by the provided service worker. In case it is
required by the app itself, the added route is named C<webpush.save>.

=head2 subs_session2user_p

Required. The code to be called to look up the user currently identified
by this session, which returns a promise of the user ID. Must reject
if no user logged in and that matters. It will be passed parameters:

=over

=item *

The L<Mojolicious::Controller/session> object, to correctly identify
the user.

=back

=head2 subs_create_p

Required. The code to be called to store users registered for push
notifications, which must return a promise of a true value if the
operation succeeds, or reject with a reason. It will be passed parameters:

=over

=item *

The ID to correctly identify the user. Please note that you ought to
allow one person to have several devices with web-push enabled, and to
design accordingly.

=item *

The C<subscription_info> hash-ref, needed to push actual messages.

=back

=head2 subs_read_p

Required. The code to be called to look up a user registered for push
notifications. It will be passed parameters:

=over

=item *

The opaque information your app uses to identify the user.

=back

Returns a promise of the C<subscription_info> hash-ref. Must reject if
not found.

=head2 subs_delete_p

Required. The code to be called to delete up a user registered for push
notifications. It will be passed parameters:

=over

=item *

The opaque information your app uses to identify the user.

=back

Returns a promise of the deletion result. Must reject if not found.

=head2 ecc_private_key

A value to be passed to L<Crypt::PK::ECC/new>: a simple scalar is a
filename, a scalar-ref is the actual key. If not provided,
L</webpush.authorization> will (obviously) not be able to function.

=head2 claim_sub

A value to be used as the C<sub> claim by the L</webpush.authorization>,
which needs it. Must be either an HTTPS or C<mailto:> URL.

=head2 claim_exp_offset

A value to be added to current time, in seconds, in the C<exp> claim
for L</webpush.authorization>. Defaults to 86400 (24 hours). The maximum
valid value in RFC 8292 is 86400.

=head2 push_handler

Override the default push-event handler supplied to
L<Mojolicious::Plugin::ServiceWorker/add_event_listener>. The default
will interpret the message as a JSON object. The key C<title> will be
the notification title, deleted from that object, then the object will be
the options passed to C<< <ServiceWorkerRegistration>.showNotification >>.

See
L<https://developers.google.com/web/fundamentals/push-notifications/handling-messages>
for possibilities.

=head1 HELPERS

=head2 webpush.create_p

  $c->webpush->create_p($user_id, $subs_info)->then(sub {
    $c->render(json => { data => { success => \1 } });
  });

=head2 webpush.read_p

  $c->webpush->read_p($user_id)->then(sub {
    $c->render(text => 'Info: ' . to_json(shift));
  });

=head2 webpush.delete_p

  $c->webpush->delete_p($user_id)->then(sub {
    $c->render(json => { data => { success => \1 } });
  });

=head2 webpush.authorization

  my $header_value = $c->webpush->authorization;

Won't function without L</claim_sub> and L</ecc_private_key>. Returns
a suitable C<Authorization> header value to send to a push service.
Valid for a period defined by L</claim_exp_offset>. Not currently cached,
but could become so to avoid unnecessary computation.

=head2 webpush.aud

  my $aud = $c->webpush->aud;

Gives the app's value it will use for the C<aud> JWT claim, useful mostly
for testing.

=head2 webpush.public_key

  my $pkey = $c->webpush->public_key;

Gives the app's public VAPID key, calculated from the private key.

=head2 webpush.verify_token

  my $bool = $c->webpush->verify_token($authorization_header_value);

Cryptographically verifies a JSON Web Token (JWT), such as generated
by L</webpush.authorization>.

=head2 webpush.encrypt

  use MIME::Base64 qw(decode_base64url);
  my $ciphertext = $c->webpush->encrypt($data_bytes,
    map decode_base64url($_), @{$subscription_info->{keys}}{qw(p256dh auth)}
  );

Returns the data encrypted according to RFC 8188, for the relevant
subscriber.

=head2 webpush.send_p

  my $result_p = $c->webpush->send_p($jsonable_data, $user_id, $ttl, $urgency);

JSON-encodes the given value, encrypts it according to the given user's
subscription data, adds a VAPID C<Authorization> header, then sends it
to the relevant web-push endpoint.

Returns a promise of the result, which will be a hash-ref with either a
C<data> key indicating success, or an C<errors> key for an array-ref of
hash-refs with a C<message> giving reasons.

If the sending gets a status code of 404 or 410, this indicates the
subscriber has unsubscribed, and L</webpush.delete_p> will be used to
remove the registration. This is considered success.

The C<urgency> must be one of C<very-low>, C<low>, C<normal> (the default)
or C<high>. The C<ttl> defaults to 30 seconds.

=head1 TEMPLATES

Various templates are available for including in the app's templates:

=head2 webpush-askPermission.html.ep

JavaScript functions, also for putting inside a C<script> element:

=over

=item *

askPermission

=item *

subscribeUserToPush

=item *

sendSubscriptionToBackEnd

=back

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

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

L<Mojolicious::Command::webpush> - command-line control of web-push.

RFC 8292 - Voluntary Application Server Identification (for web push).

L<Crypt::RFC8188> - Encrypted Content-Encoding for HTTP (using C<aes128gcm>).

L<https://developers.google.com/web/fundamentals/push-notifications>

=head1 ACKNOWLEDGEMENTS

Part of this code is ported from
L<https://github.com/web-push-libs/pywebpush>.

=cut

__DATA__

@@ webpush-askPermission.html.ep
% # from https://developers.google.com/web/fundamentals/push-notifications/subscribing-a-user
function askPermission() {
  return new Promise(function(resolve, reject) {
    const permissionResult = Notification.requestPermission(resolve);
    if (permissionResult) permissionResult.then(resolve, reject);
  })
  .then(result => result === 'granted' ? result : Promise.reject(result));
}
function subscribeUserToPush() {
  return navigator.serviceWorker.register(
    <%== Mojo::JSON::encode_json(url_for(app->serviceworker->route)) %>
  ).then(registration => registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(
      <%== Mojo::JSON::encode_json(app->webpush->public_key) %>
    )
  }));
}
function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - base64String.length % 4) % 4);
  const base64 = (base64String + padding)
    .replace(/\-/g, '+')
    .replace(/_/g, '/')
  ;
  const rawData = window.atob(base64);
  return Uint8Array.from([...rawData].map((char) => char.charCodeAt(0)));
}
function sendSubscriptionToBackEnd(subscription) {
  return fetch(<%== Mojo::JSON::encode_json(url_for 'webpush.save') %>, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(subscription)
  })
  .then(function(response) {
    if (!response.ok) throw new Error(response.statusText);
    return response.json();
  })
  .then(function(responseData) {
    if (!(responseData.data && responseData.data.success)) {
      throw new Error(responseData.errors[0].message);
    }
  });
}
