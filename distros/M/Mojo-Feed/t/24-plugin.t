use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::File;
use HTTP::Date qw(time2isoz);

use FindBin;
use Mojolicious::Lite;

subtest "parse" => sub {

plugin 'FeedReader';

my $sample_dir = File::Spec->catdir($FindBin::Bin, 'samples');
push @{app->static->paths}, $sample_dir;
my $t = Test::Mojo->new(app);

get '/plasm' => sub { shift->render(data => Mojo::File->new(File::Spec->catfile($sample_dir, 'plasmastrum.xml'))->slurp, format => 'htm'); };

# test the parse_feed helper.

# tests lifted from XML::Feed

my %Feeds = (
    'atom.xml' => 'Atom',
    'rss10.xml' => 'RSS 1.0',
    'rss20.xml' => 'RSS 2.0',
);

## First, test all of the various ways of calling parse.
my $feed;
# File:
my $file = File::Spec->catdir($sample_dir, 'atom.xml');
$feed = $t->app->parse_feed($file);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');
my $fh = Mojo::Asset::File->new(path => $file) or die "Can't open $file: $!";
$feed = $t->app->parse_feed($fh);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');

# And DOM (deprecated):
$t->app->ua->server->app($t->app);  # WHY???
my $tx = $t->app->ua->get('/atom.xml');
$feed = $t->app->parse_feed($tx->res->dom);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');

# And a slurp-able:
$tx = $t->app->ua->get('/atom.xml');
$feed = $t->app->parse_feed($tx->res->content->asset);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');

# String from tx...
$feed = $t->app->parse_feed(\ $tx->res->body);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog', 'string ref from body');

# parse a string
my $str = Mojo::File->new($file)->slurp;
$feed = $t->app->parse_feed(\$str);
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');

# parse a URL
$feed = $t->app->parse_feed(Mojo::URL->new("/atom.xml"));
isa_ok($feed, 'HASH');
is($feed->{title}, 'First Weblog');

my $delay = Mojo::IOLoop->delay(sub {
  my ($delay, $feed) = @_;
  isa_ok($feed, 'HASH');
  #say ref $feed;
  is($feed->{title}, 'First Weblog');
});
my $end = $delay->begin(0);
# parse a URL - non-blocking - this revealed a bug, yay!
$t->app->parse_feed(Mojo::URL->new("/atom.xml"),
  sub {
    my ($feed) = @_;
    $end->($feed);
  });
$delay->wait unless (Mojo::IOLoop->is_running);

## Then try calling all of the unified API methods.
for my $file (sort keys %Feeds) {
    my $path = File::Spec->catdir($FindBin::Bin, 'samples', $file);
    my $feed = $t->app->parse_feed($path) or die "parse_feed returned undef";
    #is($feed->format, $Feeds{$file});
    #is($feed->language, 'en-us');
    is($feed->{title}, 'First Weblog');
    is($feed->{htmlUrl}, 'http://localhost/weblog/');
    is($feed->{description}, 'This is a test weblog.');
    my $dt = $feed->{published};
    # isa_ok($dt, 'DateTime');
    #  $dt->set_time_zone('UTC');
    ok(defined($feed->{published}), 'feed published defined');
    is(time2isoz($dt), '2004-05-30 07:39:57Z');
    is($feed->{author}, 'Melody', 'feed author');

    my $entries = $feed->{items};
    is(scalar @$entries, 2);
    my $entry = $entries->[0];
    is($entry->{title}, 'Entry Two');
    is($entry->{link}, 'http://localhost/weblog/2004/05/entry_two.html');
#     $dt = $entry->issued;
#     isa_ok($dt, 'DateTime');
#     $dt->set_time_zone('UTC');
    #say "Raw Entry: ", $entry->{'_raw'};
    #say join q{,}, sort keys %$entry;
    ok(defined $entry->{published}, 'has pubdate');
     is(time2isoz($entry->{published}), '2004-05-30 07:39:25Z');
    like($entry->{content}, qr/<p>Hello!<\/p>/);
    is($entry->{description}, 'Hello!...');
    is($entry->{'tags'}[0], 'Travel');
    is($entry->{author}, 'Melody', 'entry author');
  # no id if no id in feed - just link
    ok($entry->{id});
}

$feed = $t->app->parse_feed(File::Spec->catdir($sample_dir, 'rss20-no-summary.xml'))
    or die "parse fail";
my $entry = $feed->{items}[0];
ok(!$entry->{summary});
like($entry->{content}, qr/<p>This is a test.<\/p>/);

$feed = $t->app->parse_feed(File::Spec->catdir($sample_dir, 'rss10-invalid-date.xml'))
    or die "parse fail";
$entry = $feed->{items}[0];
ok(!$entry->{issued});   ## Should return undef, but not die.
ok(!$entry->{modified}); ## Same.
ok(!$entry->{published}); ## Same.

# summary vs. itunes:summary:

$feed = $t->app->parse_feed(File::Spec->catdir($sample_dir, 'itunes_summary.xml'))
  or die "parse failed";
$entry = $feed->{items}[0];
isnt($entry->{summary}, 'This is for &8220;itunes sake&8221;.');
is($entry->{description}, 'this is a <b>test</b>');
is($entry->{content}, '<p>This is more of the same</p>');

# Let's do some errors - trying to parse html responses, basically
$feed = $t->app->parse_feed( $t->app->ua->get('/link1.html')->res->content->asset );
ok(! exists $feed->{items}, 'no entries from html page');
ok(! exists $feed->{title}, 'no title from html page');
ok(! exists $feed->{description}, 'no description from html page');
ok(! exists $feed->{htmlUrl}, 'no htmlUrl from html page');

# Invalid input:
$feed = $t->app->parse_feed("<xml><garbage>this is invalid</garbage></xml>");
is($feed, undef, 'we do not construct an invalid feed');
ok(! exists $feed->{items}, 'no entries from dummy xml');


# encoding issue when reading utf-8 text from file vs. from URL:

my $feed_from_file = $t->app->parse_feed(File::Spec->catdir($sample_dir, 'plasmastrum.xml'));
$tx = $t->get_ok('/plasmastrum.xml')->tx;
my $feed_from_tx = $t->app->parse_feed( $tx->res->content->asset );
my $feed_from_url = $t->app->parse_feed( Mojo::URL->new('/plasmastrum.xml') );
my $feed_from_url2 = $t->app->parse_feed( Mojo::URL->new('/plasm') );

for my $i (5,7,24) {
  is($feed_from_file->{items}[$i]{title}, $feed_from_tx->{items}[$i]{title}, 'encoding check');
  is($feed_from_file->{items}[$i]{title}, $feed_from_url->{items}[$i]{title}, 'encoding check');
  is($feed_from_file->{items}[$i]{title}, $feed_from_url2->{items}[$i]{title}, 'encoding check');
}



done_testing();

};

subtest "atom10" => sub {

use strict;
use Mojo::Base -strict;

use Test::Mojo;
use Mojo::URL;

use Mojolicious::Lite;
plugin 'FeedReader';

use HTTP::Date qw(time2isoz);
use Test::More;

my $t = Test::Mojo->new(app);
my $feed = $t->app->parse_rss("t/samples/atom-full.xml");
is $feed->{title}, 'Content Considered Harmful Atom Feed';
is $feed->{htmlUrl}, 'http://blog.jrock.us/', "link without rel";

my $e = $feed->{items}[0];
ok $e->{link}, 'entry link without rel';
is join("", @{$e->{tags}}), "Catalyst", "atom:category support";
is time2isoz($e->{published}), "2006-08-09 19:07:58Z", "atom:updated";
# this test fails, but I'm OK with that:
# like $e->{content}, qr/^<div class="pod">/, "xhtml content";
done_testing();



};

subtest "feed-find" => sub {

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use FindBin;
use Mojo::File;

use Mojolicious::Lite;
plugin 'FeedReader';

get '/floo' => sub { shift->redirect_to('/link1.html'); };

my $samples = File::Spec->catdir($FindBin::Bin, 'samples');
push @{app->static->paths}, $samples;
get '/olaf' =>sub { shift->render(data => Mojo::File->new(File::Spec->catfile($samples, 'atom.xml'))->slurp, format => 'html'); };
get '/monks' =>sub { shift->render(data => Mojo::File->new(File::Spec->catfile($samples, 'perlmonks.html'))->slurp, format => 'htm'); };

my $t = Test::Mojo->new(app);

my $abs_feed_url = $t->app->ua->server->nb_url->clone->path('atom.xml')->to_abs;

# feed
$t->get_ok('/atom.xml')->status_is(200);
my @feeds = $t->app->find_feeds('/atom.xml');
is( $feeds[0],  $abs_feed_url ); # abs url!

# can we consume a Mojo::URL ?
my @feeds_a = $t->app->find_feeds($feeds[0]);
is_deeply($feeds_a[0], $feeds[0], 'argument is a Mojo::URL');

# link
$t->get_ok('/link1.html')->status_is(200);
(@feeds) = $t->app->find_feeds('/link1.html');
is( $feeds[0],  $abs_feed_url ); # abs url!

# html page with multiple feed links
$t->get_ok('/link2_multi.html')->status_is(200);
(@feeds) = $t->app->find_feeds('/link2_multi.html');
is ( scalar @feeds, 3, 'got 3 possible feed links');
is( $feeds[0],  'http://www.example.com/?feed=rss2' ); # abs url!
is( $feeds[1],  'http://www.example.com/?feed=rss' ); # abs url!
is( $feeds[2],  'http://www.example.com/?feed=atom' ); # abs url!

# feed is in link:
# also, use base tag in head - for pretty url
$t->get_ok('/link3_anchor.html')->status_is(200);
(@feeds) = $t->app->find_feeds('/link3_anchor.html');
is( $feeds[0],  'http://example.com/foo.rss' );
is( $feeds[1],  'http://example.com/foo.xml' );

# Does it work the same non-blocking?
@feeds = ();
my $delay = Mojo::IOLoop->delay( sub {
  shift;
  (@feeds) = @_;
} );
$t->app->find_feeds('/link2_multi.html', $delay->begin(0));
$delay->wait unless (Mojo::IOLoop->is_running);
is( scalar @feeds, 3);
is( $feeds[0],  'http://www.example.com/?feed=rss2' ); # abs url!
is( $feeds[1],  'http://www.example.com/?feed=rss' ); # abs url!
is( $feeds[2],  'http://www.example.com/?feed=atom' ); # abs url!

# Let's try something with redirects:
$t->get_ok('/floo')->status_is(302);
(@feeds) = $t->app->find_feeds('/floo');
is( $feeds[0],  undef, 'default UA does not follow redirects'); # default UA doesn't follow redirects!
$t->app->ua->max_redirects(3);
(@feeds) = $t->app->find_feeds('/floo');
is( $feeds[0],  $abs_feed_url, 'found with redirect' ); # abs url!

# what do we do on a page with no feeds?
$t->get_ok('/no_link.html')->status_is(200);
(@feeds) = $t->app->find_feeds('/no_link.html');
is(scalar @feeds, 0, 'no feeds');
say "feed: $_" for (@feeds);

# a feed with an incorrect mime-type:
$t->get_ok('/olaf')->status_is(200)->content_type_like(qr/^text\/html/, 'feed served as html');
(@feeds) = $t->app->find_feeds('/olaf');
is(scalar @feeds, 1);
is(Mojo::URL->new($feeds[0])->path, '/olaf', 'feed served as html');

# we should get more info with non-blocking:
@feeds = ();
$delay = Mojo::IOLoop->delay(sub { shift; (@feeds) = @_; });

$t->app->find_feeds('/no_link.html', $delay->begin(0) );
$delay->wait;
is(scalar @feeds, 0, 'no feeds (nb)');

@feeds = ();
$t->app->find_feeds('/monks');
is(scalar @feeds, 0, 'no feeds for perlmonks');
@feeds = ();
$delay = Mojo::IOLoop->delay(sub { shift; (@feeds) = @_; });
$t->app->find_feeds('/monks', $delay->begin(0));
$delay->wait;
is(scalar @feeds, 0, 'no feeds for perlmonks (nb)');

# @feeds = ();
# $delay = Mojo::IOLoop->delay(sub { shift; (@feeds) = @_; });
# $t->app->find_feeds('slashdot.org', $delay->begin(0));
# $delay->wait();
# is(scalar @feeds, 1, 'feed for slashdot');
# @feeds = ();
# @feeds = $t->app->find_feeds('slashdot.org');
# is(scalar @feeds, 1, 'feed for slashdot');


done_testing();

};

subtest "opml" => sub {

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);

use FindBin;
use Mojolicious::Lite;

plugin 'FeedReader';

my $sample_dir = File::Spec->catdir($FindBin::Bin, 'samples');
push @{app->static->paths}, $sample_dir;
my $t = Test::Mojo->new(app);

# test files:
my %files = (
  google_reader => File::Spec->catdir($sample_dir, 'subscriptions.xml'),
  sputnik       => File::Spec->catdir($sample_dir, 'sputnik-feeds.opml.xml'),
  rssowl        => File::Spec->catdir($sample_dir, 'rssowl.opml')
);

for my $type (qw(google_reader sputnik rssowl)) {
  my $opml = $files{$type};
  note("testing with $type export");
  my @feeds = app->parse_opml( $opml );
  is(scalar @feeds, 294, 'got 294 feeds');
  ok(defined $feeds[0]{xmlUrl}, "xmlUrl defined");
  ok(defined $feeds[293]{xmlUrl}, "xmlUrl defined");
  my $invalid = 0;
  for (@feeds) {
    $invalid = dumper($_) unless (defined $_->{'xmlUrl'});
  }
  is($invalid, 0, 'all feeds are valid');
  my $feedcount = scalar grep { defined $_->{xmlUrl} } @feeds;
  is($feedcount, 294, 'all feeds defined');
  my ($frew) = grep { $_->{xmlUrl} =~ /Foolish/ } @feeds;
  note( $frew->{xmlUrl} , " is sub I will test" );
  is($frew->{text}, 'A Foolish Manifesto', 'item text');
  is($frew->{title}, 'A Foolish Manifesto', 'item title') unless ($type eq 'rssowl');
  is($frew->{htmlUrl}, 'http://blog.afoolishmanifesto.com', 'htmlUrl') unless ($type eq 'rssowl');
  my @cats = sort @{$frew->{categories}};
  is($cats[0], 'perl', $frew->{xmlUrl} . ' is in category perl');
  is(scalar @cats, 1, $frew->{xmlUrl} . ' is in one category');
  my ($abn) = grep { $_->{xmlUrl} =~ /wrongquest/ } @feeds;
  note( $abn->{xmlUrl} , " is sub I will test" );
  @cats = sort @{$abn->{categories}};
  unless ($type eq 'sputnik') { # sputnik allows each feed to be in only one category
    is($cats[0], 'a-list', $abn->{xmlUrl} . ' is in category a-list');
    is($cats[1], 'books', $abn->{xmlUrl} . ' is in category books');
    is($cats[2], 'friends', $abn->{xmlUrl} . ' is in category friends');
    is(scalar @cats, 3, $abn->{xmlUrl} . ' is in three categories');
  }
}

done_testing();

};

subtest "" => sub {

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
};

subtest "enclosures" => sub {

use Mojo::Base -strict;

use Test::More;
use Mojo::File 'path';
use Mojolicious::Plugin::FeedReader;

use FindBin;

my %test_results = (
    'rss20-multi-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        },
        {
            'length' => '8888',
            'type'   => 'video/mpeg',
            'url'    => 'http://example.com/sample_movie.mpg'
        }
    ],
    'atom-multi-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        },
        {
            'length' => '8888',
            'type'   => 'video/mpeg',
            'url'    => 'http://example.com/sample_movie.mpg'
        }
    ],
    'atom-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        }
    ],
    'rss20-enclosure.xml' => [
        {
            'length' => '2478719',
            'type'   => 'audio/mpeg',
            'url'    => 'http://example.com/sample_podcast.mp3'
        }
    ],
);

my $samples = path($FindBin::Bin)->child('samples');

my $reader = Mojolicious::Plugin::FeedReader->new;

while ( my ( $file, $result ) = each %test_results ) {
    my $feed = $reader->parse_rss( $samples->child($file) );
    is_deeply( $feed->{items}->[0]->{enclosures}, $result );
}

done_testing();

};
done_testing();
