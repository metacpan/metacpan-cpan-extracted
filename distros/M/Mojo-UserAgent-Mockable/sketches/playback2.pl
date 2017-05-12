use 5.014;
use Mojo::UserAgent;
use Mojolicious;
my $ua = Mojo::UserAgent->new;

my $ua = Mojo::UserAgent->new;
#die q{No server} unless $ua->server->{server};
#
#$ua->server->{server}->on( request => sub {
#    my ($server, $tx) = @_;
#    $tx->res->code(200);
#    $tx->res->headers->content_type('text/plain');
#    $tx->res->body('Go away!');
#    $tx->resume;
#});

my $tx = $ua->get('http://www.example.com/');
say $tx->res->headers->to_string;
say $tx->res->body;

my $app = Mojolicious->new;
$app->routes->any(
    '/*any' => { any => '' } => sub { shift->render( text => q{Don't go away} ) }
);
$ua->server->app($app);
$tx = $ua->get('/foobar');
say $tx->res->headers->to_string;
say $tx->res->body;
