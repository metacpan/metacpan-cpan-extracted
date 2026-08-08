package Chat;

use Punk;
use File::Basename ();
use Chat::Auth ();

# Punk Chat - the example application.
#
# Four things share one app class, one router and one model tier:
#
#   * a Stencil-rendered web page (the chat UI),
#   * a WebSocket route per room, broadcasting through a Punk room,
#   * a spec-first OpenAPI mount whose writes land in the same table and
#     fan out to the live sockets, with the docs UI over it,
#   * a written guide, from a directory of markdown under /guide.
#
# HTTPS is not configured here, and deliberately so: TLS is a listener
# property, not an application one. bin/punk-chat terminates TLS in front
# of this app - see README.pod for why that is the only shape that serves
# wss:// on a Hyperman deployment.

my $home = File::Basename::dirname(__FILE__) . '/..';

views Stencil => {
    template_dir => "$home/root/templates",
    wrapper      => 'layout.tmpl',
};

static '/static' => "$home/root/static";

# The written guide, from a directory of markdown. Rendered once at boot -
# tree walked, pages wrapped, search index filled - and served from frozen
# bytes thereafter, so a docs request costs a hash lookup. PUNK_CHAT_DEV
# turns on the re-render-on-change path for writing them.
#
# Note this is not the same thing as `docs` further down: that one generates
# the interactive reference from the OpenAPI spec. Prose and generated
# reference answer different questions, and an app usually wants both.
markdown '/guide' => "$home/docs",
    title  => 'Punk Chat Guide',
    reload => $ENV{PUNK_CHAT_DEV} ? 1 : 0;

# Punk::Model::DBIx::Loop, not the default Punk::Model::DBI: every model
# call then returns a Punk::Future and the query runs on the worker's own
# event loop instead of stopping it. See README.pod.
database dsn     => $ENV{PUNK_CHAT_DSN} || "dbi:SQLite:dbname=$home/chat.db",
         backend => 'Punk::Model::DBIx::Loop';
model 'Message';

# ---- the web tier ----------------------------------------------------------

get '/'           => 'Web::Chat#index';
get '/chat/:room' => 'Web::Chat#room';

# ---- the live tier ---------------------------------------------------------

# Routes like any GET, so it sits under the same router and could sit under
# the same guards; the handler is called with the connection once the
# upgrade handshake has been validated and answered.
websocket '/ws/:room' => 'WS::Chat#join_room', {
    protocols        => [ 'punk.chat.v1' ],
    max_message_size => 65_536,
};

# ---- the API tier ----------------------------------------------------------

# The spec is the routing table: every operationId in openapi.json resolves
# to a method under Chat::Controller::API at boot, and a typo croaks before
# the app serves a request. `security` wires the spec's bearer scheme to a
# checker - an operation that requires a scheme with no checker croaks too,
# so there is no way to leave the door open by omission.
my $api = under('/api')->api("$home/openapi.json", {
    security => { adminToken => \&Chat::Auth::admin_token },
});

docs '/docs' => $api;

1;
