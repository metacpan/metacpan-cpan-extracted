use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::File qw(path);
use HTTP::Date qw(time2isoz);

use FindBin;
use Mojolicious::Lite;
use Mojo::Feed;
use Mojo::Feed::Reader;

my $sample_dir = path( $FindBin::Bin, 'samples' );
push @{ app->static->paths }, $sample_dir;
my $t = Test::Mojo->new(app);

get '/plasm' => sub {
    shift->render(
        data   => path( $sample_dir, 'plasmastrum.xml' )->slurp,
        format => 'htm'
    );
};

# test the parse_feed helper.

# tests lifted from XML::Feed

my %Feeds = (
    'atom.xml'  => 'Atom',
    'rss10.xml' => 'RSS 1.0',
    'rss20.xml' => 'RSS 2.0',
);

## First, test all of the various ways of calling parse.
my $feed;

# File:
my $file = path( $sample_dir, 'atom.xml' );
$feed = Mojo::Feed::Reader->new->parse($file);
isa_ok( $feed, 'Mojo::Feed' );
is( $feed->title, 'First Weblog', 'title ok' );
is ( $feed->source, $file , 'source ok' );

# parse a string
my $str = Mojo::File->new($file)->slurp;
$feed = Mojo::Feed->new( body => $str);
isa_ok( $feed, 'Mojo::Feed' );
is( $feed->title, 'First Weblog', 'title ok' );
ok ( !$feed->source,'source ok' );

# parse a URL
$feed =
  Mojo::Feed::Reader->new->ua( $t->app->ua )->parse( Mojo::URL->new("/atom.xml") );
isa_ok( $feed, 'Mojo::Feed' );
is( $feed->title, 'First Weblog', 'title ok' );
is ( $feed->source->path, '/atom.xml' , 'source ok' );

## Callback and non-blocking no longer supported - how do we make a promise API?

my $feedr = Mojo::Feed::Reader->new;
## Then try calling all of the unified API methods.
for my $file ( sort keys %Feeds ) {
    my $path = path( $FindBin::Bin, 'samples', $file );
    my $feed = $feedr->parse($path) or die "parse feed returned undef";

    #is($feed->format, $Feeds{$file});
    #is($feed->language, 'en-us');
    is( $feed->title,       'First Weblog' );
    is( $feed->html_url,    'http://localhost/weblog/' );
    is( $feed->description, 'This is a test weblog.' );
    my $dt = $feed->published;

    # isa_ok($dt, 'DateTime');
    #  $dt->set_time_zone('UTC');
    ok( defined( $feed->published ), 'feed published defined' );
    is( time2isoz($dt), '2004-05-30 07:39:57Z' );
    is( $feed->author, 'Melody', 'feed author' );

    my $entries = $feed->items;
    is( scalar @$entries, 2 );
    my $entry = $entries->[0];
    is( $entry->title, 'Entry Two' );
    is( $entry->link,  'http://localhost/weblog/2004/05/entry_two.html' );

    #     $dt = $entry->issued;
    #     isa_ok($dt, 'DateTime');
    #     $dt->set_time_zone('UTC');
    #say "Raw Entry: ", $entry->{'_raw'};
    #say join q{,}, sort keys %$entry;
    ok( defined $entry->published, 'has pubdate' );
    is( time2isoz( $entry->published ), '2004-05-30 07:39:25Z' );
    like( $entry->content, qr/<p>Hello!<\/p>/ );
    is( $entry->description, 'Hello!...' );
    is( $entry->tags->[0],   'Travel' );
    is( $entry->author,      'Melody', 'entry author' );

    # no id if no id in feed - just link
    ok( $entry->id );

    is ( $entry->feed, $feed, 'reference for feed' );
    undef $feed;
    ok ( !$entry->feed, 'weak reference for feed');
}

$feed = $feedr->parse( path( $sample_dir, 'rss20.xml' ) )
  or die "parse fail";
my $entry = $feed->items->[0];
ok(
    $entry->summary ne $entry->content,
    'description and content are different'
);

$feed =
  $feedr->parse( path( $sample_dir, 'rss20-no-summary.xml' ) )
  or die "parse fail";
$entry = $feed->items->[0];
ok( $entry->summary eq $entry->content, 'no summary use content/description' );
like( $entry->content, qr/<p>This is a test.<\/p>/ );

$feed =
  $feedr->parse( path( $sample_dir, 'rss10-invalid-date.xml' ) )
  or die "parse fail";
$entry = $feed->items->[0];
ok( !$entry->{issued} );       ## Should return undef, but not die.
ok( !$entry->{modified} );     ## Same.
ok( !$entry->{published} );    ## Same.

# summary vs. itunes:summary:

$feed =
  $feedr->parse( path( $sample_dir, 'itunes_summary.xml' ) )
  or die "parse failed";
$entry = $feed->items->[0];
isnt( $entry->summary, 'This is for &8220;itunes sake&8221;.' );
is( $entry->description, 'this is a <b>test</b>' );
is(
    $entry->content, '<p>This is more of the same</p>
'
);

# author vs itunes:author:
# does the order of the tags change which one we pick?
$feed = $feedr->parse( path($sample_dir, 'itunes_author_order.xml') )
        or die "parse failed";
is($feed->items->[0]->author, 'webmaster@kcrw.org (KCRW, Elvis Mitchell)', 'author not itunes:author');
is($feed->items->[1]->author, 'webmaster@kcrw.org (KCRW, Elvis Mitchell)', 'author not itunes:author, despite order');

# Let's do some errors - trying to parse html responses, basically
$feed = Mojo::Feed->new( body => $t->app->ua->get('/link1.html')->res->body );
ok( ! $feed->is_valid, "feed is not valid");
is( scalar $feed->items->each, 0,     'no entries from html page' );
is( $feed->title,              undef, 'no title from html page' );
is( $feed->description,        undef, 'no description from html page' );
is( $feed->html_url,           undef, 'no htmlUrl from html page' );

# Invalid input:
$feed = $feedr->parse("<xml><garbage>this is invalid</garbage></xml>");
is($feed, undef, "invalid feed not defined");
ok(! exists $feed->{items}, 'no entries from dummy xml');

# encoding issue when reading utf-8 text from file vs. from URL:

my $feed_from_file =
  $feedr->parse( path( $sample_dir, 'plasmastrum.xml' ) );
my $tx            = $t->get_ok('/plasmastrum.xml')->tx;
my $feed_from_tx  = Mojo::Feed::Reader->new->ua( $t->app->ua )->parse( $tx->res->body );
my $feed_from_url = Mojo::Feed::Reader->new->ua( $t->app->ua )
  ->parse( Mojo::URL->new('/plasmastrum.xml') );
my $feed_from_url2 =
  Mojo::Feed::Reader->new->ua( $t->app->ua )->parse( Mojo::URL->new('/plasm') );

for my $i ( 5, 7, 24 ) {
    is(
        $feed_from_file->items->[$i]->title,
        $feed_from_tx->items->[$i]->title,
        'encoding check'
    );
    is(
        $feed_from_file->items->[$i]->title,
        $feed_from_url->items->[$i]->title,
        'encoding check'
    );
    is(
        $feed_from_file->items->[$i]->title,
        $feed_from_url2->items->[$i]->title,
        'encoding check'
    );
}

done_testing();
