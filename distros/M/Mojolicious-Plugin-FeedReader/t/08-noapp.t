use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::File 'path';
use Mojolicious::Plugin::FeedReader;
use Mojolicious::Lite;

use FindBin;

my $t = Test::Mojo->new(app);
push @{ app->static->paths }, path($FindBin::Bin)->child('samples');

my $reader = Mojolicious::Plugin::FeedReader->new( ua => $t->app->ua );
my $feed;

# parse a URL
$feed = $reader->parse_rss( Mojo::URL->new("/atom.xml") );
is( $feed->{title}, 'First Weblog' );

my $delay = Mojo::IOLoop->delay(
    sub {
        my ( $delay, $feed ) = @_;
        is( $feed->{title}, 'First Weblog' );
    }
);
my $end = $delay->begin(0);

# parse a URL - non-blocking - this revealed a bug, yay!
$reader->parse_rss(
    Mojo::URL->new("/atom.xml"),
    sub {
        my ($feed) = @_;
        $end->($feed);
    }
);
$delay->wait unless ( Mojo::IOLoop->is_running );

done_testing();
