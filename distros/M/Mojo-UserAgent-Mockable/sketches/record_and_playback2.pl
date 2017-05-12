use 5.014;
use Mojo::UserAgent;
use Mojo::Message::Serializer;
use DDP;
use Mojolicious;

my $ua = Mojo::UserAgent->new;

my $file = '/tmp/serial_test.json';
my $serializer = Mojo::Message::Serializer->new();
my ($req, $res);
my $start = $ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;

        $res = $serializer->serialize( $tx->req );
        $tx->on(
            finish => sub {
                my $tx = shift;
                $serializer->store( $file, $tx->res );
            }
        );
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
$ua = undef;
# At this point, I should have the recorded request and response.

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
say $tx->res->headers->to_string;
say $tx->res->body;
$ua->unsubscribe(start => $start);

