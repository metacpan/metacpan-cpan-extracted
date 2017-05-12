use Mojo::Server::Daemon;
use Mojo::IOLoop;
 
my $app = Mojolicious->new;
$app->routes->any( ... );
 
my $daemon = Mojo::Server::Daemon->new(
    app => $app, 
    ioloop => Mojo::IOLoop->singleton,
    silent => 1,
);
 
my $listen = q{http://127.0.0.1};
$daemon->listen( [$listen] )->start;
my $port = Mojo::IOLoop->acceptor( $daemon->acceptors->[0] )->port;
my $url  = Mojo::URL->new(qq{$listen:$port})->userinfo('joeblow:foobar');
 
my $output_file = qq{/path/to/file.json};
 
my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file);
my $tx = $mock->get($url);
