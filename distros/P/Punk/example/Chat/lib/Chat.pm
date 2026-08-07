package Chat;

use Punk;
use File::Basename ();
use Chat::Auth ();

# Punk Chat - the example application.
#
# Three things share one app class, one router and one model tier:
#
#   * a Stencil-rendered web page (the chat UI),
#   * a WebSocket route per room, broadcasting through a Punk room,
#   * a spec-first OpenAPI mount whose writes land in the same table and
#     fan out to the live sockets, with the docs UI over it.
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

database dsn => $ENV{PUNK_CHAT_DSN} || "dbi:SQLite:dbname=$home/chat.db";
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
