use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use FindBin;
use Mojo::File qw(path);

use Mojolicious::Lite;

use Mojo::Feed;

get '/floo' => sub { shift->redirect_to('/link1.html'); };

my $samples = path( $FindBin::Bin, 'samples' );
push @{ app->static->paths }, $samples;
get '/olaf' => sub {
    shift->render(
        data =>
           path( $samples, 'atom.xml' )->slurp,
        format => 'html'
    );
};
get '/monks' => sub {
    shift->render(
        data =>
          path( $samples, 'perlmonks.html' )->slurp,
        format => 'htm'
    );
};
get '/wp' => sub {
    shift->render(
        data => '<html><a href="/feed">subscribe</a> for updates</html>',
        format => 'html'
    );
};

get '/' => sub {
    my $self = shift;
    if ($self->param('feed') eq 'rss2') {
        $self->redirect_to('rss20.xml');
    }
    elsif ($self->param('feed') eq 'rss') {
        $self->redirect_to('rss10.xml');
    }
    elsif ($self->param('feed') eq 'atom') {
        $self->redirect_to('atom.xml');
    }
    else {
        $self->reply->not_found();
    }
};

get '/feed' => sub {
    shift->render(
        data =>
           path( $samples, 'atom.xml' )->slurp,
        format => 'html'
    );
};

my $t            = Test::Mojo->new(app);

sub abs_url {
return $t->ua->server->url->clone->path($_[0])->to_abs;
};

my $abs_feed_url = abs_url('atom.xml');

# feed

# (Mojo::URL, abs)
$t->get_ok('/atom.xml')->status_is(200);
my $feed = Mojo::Feed->new(ua => $t->ua, url => abs_url('/atom.xml'));
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, $abs_feed_url, 'Mojo::URL (abs) ok' );    # abs url!

# not a Mojo::URL:
$feed = Mojo::Feed->new(ua => $t->ua, url => "" . abs_url('/atom.xml'));
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, $abs_feed_url , "string URL (abs) ok");    # abs url!

# Just a relative URL::
$feed = Mojo::Feed->new(ua => $t->ua, url => '/atom.xml');
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, '/atom.xml', 'relative string URL ok' );    # relative url!


# link
$t->get_ok('/link1.html')->status_is(200);
$feed = Mojo::Feed->new(ua => $t->ua, url => abs_url('/link1.html'));
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, $abs_feed_url, 'link) ok' );    # abs url!

# html page with multiple feed links
$t->get_ok('/link2_multi_rel.html')->status_is(200);
$feed = Mojo::Feed->new(ua => $t->ua, url => '/link2_multi_rel.html');
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, abs_url('/rss20.xml'), 'link multi ok' );    # abs url!
my @feeds = @{$feed->related};
is( scalar @feeds, 2, 'got 2 additional feed links' );
is( $feeds[0], abs_url('/')->query(feed=>'rss') );     # abs url!
is( $feeds[1], abs_url('/')->query(feed=>'atom') );    # abs url!


# feed is in link:
# also, use base tag in head - for pretty url
$t->get_ok('/link3_anchor_no_base.html')->status_is(200);
$feed = Mojo::Feed->new(ua => $t->ua, url => '/link3_anchor_no_base.html');
is($feed->title, 'First Weblog', 'load ok'); # load it
is( $feed->url, abs_url('/rss20.xml'), 'link multi ok' );    # abs url!
@feeds = @{$feed->related};
is( scalar @feeds, 1, 'got 1 additional feed link' );
is( $feeds[0], abs_url('/atom.xml'));

# Let's try something with redirects:
$t->get_ok('/floo')->status_is(302);
$feed = Mojo::Feed->new(url => '/floo', ua => $t->ua, max_redirects => 0);
eval { $feed->title };
like( $@, qr/Number of redirects exceeded when loading feed/);
ok( ! $feed->is_valid, 'feed is invalid' );

$feed = Mojo::Feed->new(url => '/floo', ua => $t->ua);
is($feed->title, 'First Weblog', 'load ok'); # load it

is( $feed->url, abs_url('atom.xml'), 'found with redirect' );    # abs url!

# what do we do on a page with no feeds?
$t->get_ok('/no_link.html')->status_is(200);
$feed = Mojo::Feed->new(ua => $t->ua, url => '/no_link.html');
eval { $feed->title };
like( $@, qr/No valid feed found at /);
ok (!$feed, 'no feed (invalid)');

# a feed with an incorrect mime-type:
$t->get_ok('/olaf')->status_is(200)
  ->content_type_like( qr/^text\/html/, 'feed served as html' );
$feed = Mojo::Feed->new(ua => $t->ua, url => '/olaf');
is($feed->title, 'First Weblog', 'load ok'); # load it
is($feed->url, abs_url('/olaf'), 'feed served as html' );

# why just an extension? look for the word "feed" somewhere in the url
$feed = Mojo::Feed->new(ua => $t->ua, url => '/wp');
is($feed->title, 'First Weblog', 'load ok'); # load it
is($feed->url, abs_url('/feed'), 'promising url title in link');


done_testing();
__END__

@feeds = ();

$feedr->discover( '/no_link.html' )->then(sub{ (@feeds) = @_ })->wait;
is( scalar @feeds, 0, 'no feeds (nb)' );

@feeds = ();
$feedr->discover('/monks')->then(sub{ (@feeds) = @_ })->wait;
is( scalar @feeds, 0, 'no feeds for perlmonks' );
@feeds = ();
$feedr->discover( '/monks')->then(sub{ (@feeds) = @_ })->wait;
is( scalar @feeds, 0, 'no feeds for perlmonks (nb)' );

done_testing();
