use 5.014;
use Mojo::UserAgent;
use Mojo::Message::Response;
use Mojolicious;
use Mojo::Message::Serializer;
my $ua = Mojo::UserAgent->new;

my $file = $ARGV[0];
die qq{Usage: $0 <file>} unless $file;

my $serializer = Mojo::Message::Serializer->new();
my $res_unserialized = $serializer->retrieve($file);
$res_unserialized->headers->header('X-Regenerated' => 'Yes');
$ua = Mojo::UserAgent->new;
my $app = Mojolicious->new;
$app->routes->any(
    '/*any' => { any => '' } => sub {
        my $c  = shift;
        my $tx = $c->tx;
        $tx->res($res_unserialized);
        $c->rendered( $res_unserialized->code );
    }
);
$ua->server->app($app);

my $start = $ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;
        $tx->req->url->host('')->scheme('')->port($ua->server->url->port);
    }
);
my $tx = $ua->post(
    'http://requestb.in/t87607t8' => {
        'X-Zaphod-Last-Name'                => 'Beeblebrox',
        'X-Benedict-Cumberbatch-Silly-Name' => 'Bumbershoot Crinklypants'
        } => form =>
        { foo => 'bar', quux => 'quuy', thefile => { file => q{/Users/kipeters/Documents/sample resume.docx} } }
);
$ua->unsubscribe(start => $start);

say $tx->res->headers->to_string;
say $tx->res->body;
