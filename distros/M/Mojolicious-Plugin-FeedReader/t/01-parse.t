use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::URL;
use Mojo::Util qw(slurp);
use HTTP::Date qw(time2isoz);

use FindBin;
use Mojolicious::Lite;
plugin 'FeedReader';

my $sample_dir = File::Spec->catdir($FindBin::Bin, 'samples');
push @{app->static->paths}, $sample_dir;
my $t = Test::Mojo->new(app);

get '/plasm' => sub { shift->render(data => slurp(File::Spec->catfile($sample_dir, 'plasmastrum.xml')), format => 'htm'); };

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
my $str = slurp $file;
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
    my ($c, $feed) = @_;
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
is($entry->{content}, '<p>This is more of the same</p>
');

# Let's do some errors - trying to parse html responses, basically
$feed = $t->app->parse_feed( $t->app->ua->get('/link1.html')->res->content->asset );
ok(! exists $feed->{items}, 'no entries from html page');
ok(! exists $feed->{title}, 'no title from html page');
ok(! exists $feed->{description}, 'no description from html page');
ok(! exists $feed->{htmlUrl}, 'no htmlUrl from html page');


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
