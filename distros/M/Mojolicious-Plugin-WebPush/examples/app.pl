use Mojolicious::Lite;
use Mojo::File qw(curfile path);
use Mojo::Promise;
use Mojo::SQLite;
use Mojo::JSON qw(decode_json encode_json);

my $pushkeyfile = curfile->sibling('webpush_private_key.pem')
  ->to_rel(path)->to_string;
if (! -f $pushkeyfile) {
  die <<EOF;
No webpush private key file found in '$pushkeyfile'. Make one:
  $0 webpush keygen >$pushkeyfile
EOF
}

helper sqlite => sub {
  state $path = app->home->child( 'data.db' );
  state $sqlite = Mojo::SQLite->new( 'sqlite:' . $path );
  return $sqlite;
};
app->sqlite->auto_migrate(1)->migrations->from_data;

my $sw = plugin 'ServiceWorker' => {
  debug => 1,
  network_first => [
    "whoami",
  ],
  network_only => [
    "push", "api/savesubs",
  ],
};
my $webpush = plugin 'WebPush' => webpush_config();

get '/' => 'index';

post '/login' => sub {
  my $user_id = $_[0]->req->json('/user_id');
  $_[0]->session(user_id => $user_id);
  $_[0]->render(json => { data => { user_id => $user_id } });
}, 'login';

post '/push' => sub {
  my ($c) = @_;
  my $user_id = $c->session->{user_id};
  my $message = $c->req->json;
  $c->webpush->send_p($message, $user_id, 30, 'normal')->then(sub {
    $c->render(json => $_[0]);
  });
}, 'push';

get '/whoami' => sub {
  $_[0]->render(json => { user_id => $_[0]->session('user_id') });
}, 'whoami';

sub webpush_config {
  +{
    save_endpoint => '/api/savesubs',
    subs_session2user_p => \&subs_session2user_p,
    subs_create_p => \&subs_create_p,
    subs_read_p => \&subs_read_p,
    subs_delete_p => \&subs_delete_p,
    (-s $pushkeyfile ? (ecc_private_key => $pushkeyfile) : ()),
    claim_sub => 'mailto:admin@example.com',
  };
}

sub subs_session2user_p {
  return Mojo::Promise->reject("Session not logged in") if !$_[1]{user_id};
  Mojo::Promise->resolve($_[1]{user_id});
}

sub subs_create_p {
  my ($c, $user_id, $subs_info) = @_;
  app->sqlite->db->insert(
    'users',
    { username => $user_id, subs_info => encode_json($subs_info) },
  );
  Mojo::Promise->resolve(1);
}

sub subs_read_p {
  my ($c, $user_id) = @_;
  my @results = app->sqlite->db->select(
    'users',
    [qw(subs_info)],
    { username => $user_id },
  )->arrays->each;
  return Mojo::Promise->reject("Not found: '$user_id'") if !@results;
  Mojo::Promise->resolve(decode_json $results[0][0]);
}

sub subs_delete_p {
  my ($c, $user_id) = @_;
  return app->webpush->read_p($user_id)->then(sub {
    app->sqlite->db->delete('users', { username => $user_id });
    $_[0];
  });
}

app->start;

__DATA__

@@ index.html.ep
<div>You are logged in as: <span id="log"><i>not logged in</i></span></div>
<form onsubmit="login(this.children[1].value); return false">
<input type="submit" value="Login as"><input value="bob">
</form>
<p/>
<button onclick="askPermission().then(subscribeUserToPush).then(sendSubscriptionToBackEnd)">Ask permission</button>
<p/>
<form onsubmit="push(this.children[1].value); return false">
<input type="submit" value="Push message"><input value="Test push message from sample"><span id="push_status"><i>no push yet</i></span>
</form>
<script>
%= include 'serviceworker-install'
%= include 'webpush-askPermission'
var login_disp = document.getElementById('log');
function set_logged_in(u) { login_disp.innerHTML = u }
var push_status = document.getElementById('push_status');
function set_push_status(m) { push_status.innerHTML = m }
const whoami = () => fetch('whoami', { credentials: 'include' }).then(
  r => r.json()).then(j => j.user_id);
const showwhoiam = () => whoami().then(set_logged_in);
showwhoiam();
function json_fetch(url, data) {
  return fetch(url, {
    method: 'POST',
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).then(
    r => r.json()
  ).then(
    j => j.errors ? Promise.reject(j.errors[0].message) : j.data
  );
}
function login(newname) {
  return json_fetch('login', { user_id: newname }).then(
    showwhoiam,
    e => set_logged_in('<i>' + e + '</i>'),
  );
}
function push(message) {
  return json_fetch('push', { title: message, body: message }).then(
    () => set_push_status('Success'),
    e => set_push_status('<i>Push failed: ' + e + '</i>'),
  );
}
</script>

@@ migrations
-- 1 up
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username VARCHAR(100) UNIQUE NOT NULL,
    subs_info VARCHAR(255) NOT NULL
);
-- 1 down
DROP TABLE users;
