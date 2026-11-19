use Mojo::Base -strict;
use Test::More;
use Mojo::Feed::Reader;
use Mojo::Transaction::HTTP;
use Mojo::URL;

# Minimized from verify-opml/subscriptions.xml, 2026-11-18.
# Replay responses against ORIGINAL input URLs: no DNS, TLS, or public servers.
# These are intentionally red regression tests for issues not fixed yet.
{
  package Local::ReplayUA;
  use Mojo::Base 'Mojo::UserAgent';
  has replies => sub { [] };
  has requests => sub { [] };

  sub get {
    my ($self, $url) = @_;
    $url = Mojo::URL->new("$url");
    push @{$self->requests}, "$url";
    die "Unresolved relative redirect: $url\n" unless $url->is_abs;
    my $reply = shift @{$self->replies}
      or die "Unexpected request: $url\n";
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->req->url($url);
    if ($reply->{error}) {
      $tx->res->error({message => $reply->{error}});
      return $tx;
    }
    $tx->res->code($reply->{code} // 200);
    $tx->res->message($reply->{message} // $tx->res->default_message);
    $tx->res->headers->from_hash($reply->{headers} // {});
    $tx->res->body($reply->{body} // '');
    return $tx;
  }
}

my $rss = '<?xml version="1.0"?><rss version="2.0"><channel>'
  . '<title>Example</title><item><title>Post</title>'
  . '<pubDate>Sun, 15 Nov 2026 22:04:26 -0800</pubDate>'
  . '</item></channel></rss>';
my $feed_reply = {
  code => 200, headers => {'Content-Type' => 'text/xml'}, body => $rss
};

sub attempt {
  my ($url, @replies) = @_;
  my $ua = Local::ReplayUA->new(replies => \@replies);
  my (@warnings, $feed, $error);
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval {
      $feed = Mojo::Feed::Reader->new(ua => $ua)
        ->parse(Mojo::URL->new($url));
      1;
    } or $error = $@;
  }
  return ($feed, $error // '', \@warnings, $ua->requests);
}

for my $case (
  [308, 'http://altneuland.lerner.co.il/?feed=rss2'],
  [307, 'http://community.livejournal.com/theinferior4/data/atom']
) {
  my ($code, $url) = @$case;
  subtest "follow $code redirect" => sub {
    (my $target = $url) =~ s/^http:/https:/;
    my ($f, $err, $warn, $requests) = attempt($url,
      {code => $code, headers => {Location => $target}}, $feed_reply);
    is($err, '', 'no internal exception');
    is_deeply($warn, [], 'missing content type on redirect is harmless');
    is_deeply($requests, [$url, $target], 'follow HTTPS location');
    ok(defined $f, 'destination feed returned');
  };
}

subtest 'relative redirect retains original host' => sub {
  my $url = 'http://feeds.radvision.com/CodeOfContact';
  my ($f, $err, $warn, $requests) = attempt($url,
    {code => 302, headers => {Location => '/login'}},
    {headers => {'Content-Type' => 'text/html'},
      body => '<html><head><title>Login</title></head></html>'});
  is_deeply($requests, [$url, 'http://feeds.radvision.com/login'],
    'relative Location resolved before fetching');
  like($err, qr/No valid feed found at http:\/\/feeds\.radvision\.com\/login/,
    'login page produces a useful feed error, not a server exception');
  is_deeply($warn, [], 'no warnings');
};

subtest 'empty XML response is not an internal exception' => sub {
  my ($f, $err, $warn) = attempt(
    'http://feeds.feedburner.com/sintitulocomic',
    {headers => {'Content-Type' => 'text/xml; charset=utf-8'}});
  ok(!defined $f, 'no feed');
  # Reader documents undef for non-feeds; an explicit feed error is also OK.
  ok(!$err || $err =~ /(?:empty|No valid feed)/i,
    'reject empty body with undef or a meaningful error') or diag $err;
  is_deeply($warn, [], 'no warnings');
};

subtest 'missing Content-Type on a successful response' => sub {
  # Isolates the warnings seen on Altneuland/LiveJournal from redirect handling.
  my ($f, $err, $warn) = attempt(
    'http://altneuland.lerner.co.il/?feed=rss2', {body => $rss});
  is($err, '', 'sniff valid XML without a content type');
  ok(defined $f, 'feed parsed');
  is_deeply($warn, [], 'no uninitialized content_type warnings');
};

subtest 'RSS without XML declaration preserves pubDate' => sub {
  # http://feeds.feedburner.com/doctorow_podcast redirects to this RSS.
  (my $body = $rss) =~ s/^<\?xml[^>]+>//;
  my ($f, $err, $warn) = attempt(
    'http://feeds.feedburner.com/doctorow_podcast',
    {headers => {'Content-Type' => 'text/xml; charset=UTF-8'}, body => $body});
  is($err, '', 'feed accepted');
  ok(defined $f, 'feed exists');
  if (defined $f) {
    is($f->items->first->published, 1794809066,
      'valid RSS pubDate must not become undef through HTML parsing');
  }
  is_deeply($warn, [], 'no parsing warnings');
};

# Expected remote failures: keep useful diagnostics while avoiding internals.
for my $case (
  ['http://alex.dojotoolkit.org/?feed=atom',
    "Can't connect: nodename nor servname provided, or not known"],
  ['http://badgods.com/rss.xml', 'Connect timeout'],
  ['http://primevalpress.com/xml-rss2.php?blogid=1', 'Connection refused'],
  ['http://goleshet.blogli.co.il/feed/', 'Premature connection close'],
  ['http://israblog.nana10.co.il/blog_rss.asp?blog=164873',
    'hostname verification failed']
) {
  my ($url, $message) = @$case;
  subtest "transport error: $message" => sub {
    my ($f, $err, $warn) = attempt($url, {error => $message});
    ok(!defined $f, 'no feed');
    like($err, qr/\Q$message\E/, 'preserve transport cause');
    like($err, qr/\Q$url\E/, 'error includes original URL');
    is_deeply($warn, [], 'no warnings');
  };
}

for my $case (
  [401, 'http://contemplating-from-gaza.blogspot.com/feeds/posts/default'],
  [403, 'http://fuckyeahgamemasters.tumblr.com/rss'],
  [404, 'http://blog.mozilla.com/faaborg/feed/atom/'],
  [410, 'http://www.dagolden.com/index.php/feed/'],
  [500, 'http://www.awesomehospital.com/?feed=rss2'],
  [503, 'http://www.scattershotgames.com/?feed=atom'],
  [400, 'http://www.tapestrycomics.com/dilbert.xml']
) {
  my ($code, $url) = @$case;
  subtest "HTTP $code error is actionable" => sub {
    my ($f, $err, $warn) = attempt($url, {code => $code});
    ok(!defined $f, 'no feed');
    like($err, qr/\Q$url\E/, 'URL in error');
    my $reason = Mojo::Message::Response->new(code => $code)->default_message;
    like($err, qr/\Q$reason\E|$code/, 'HTTP reason or status in error');
    is_deeply($warn, [], 'no warnings');
  };
}

subtest 'HTML page without a feed link is rejected' => sub {
  my $url = 'http://blog.fantasyheartbreaker.com/feed/';
  my ($f, $err, $warn) = attempt($url,
    {headers => {'Content-Type' => 'text/html'},
      body => '<html><head><title>Parked</title></head></html>'});
  like($err, qr/No valid feed found at \Q$url\E/, 'actionable error');
  is_deeply($warn, [], 'no warnings');
};

subtest 'nonstandard HTTP status remains actionable' => sub {
  # Actual Cloudflare response: HTTP/1.1 526 <none>, empty body.
  my $url = 'http://shimshon.net/?feed=rss2';
  my ($f, $err, $warn) = attempt($url,
    {code => 301, headers => {Location => 'https://shimshon.net/?feed=rss2'}},
    {code => 526, message => '<none>'});
  like($err, qr/526/, 'include numeric status when reason is uninformative');
  like($err, qr/shimshon\.net/, 'include URL');
  is_deeply($warn, [], 'no warnings');
};

subtest 'genuinely absent optional metadata returns undef' => sub {
  for my $url ('http://sartak.org/rss.xml',
    'http://www.sjgames.com/ill/ill.xml',
    'http://feeds.feedburner.com/strawjackal') {
    my ($f, $err, $warn) = attempt($url,
      {headers => {'Content-Type' => 'text/xml'},
        body => '<?xml version="1.0"?><rss version="2.0">'
          . '<channel><title></title><item><description>Post</description>'
          . '</item></channel></rss>'});
    is($err, '', 'missing metadata is not a parse failure');
    if (defined $f) {
      is($f->title, undef, 'absent title is undef, not a fabricated value');
      is($f->items->first->published, undef, 'absent date is undef');
    }
    else { fail('valid feed with missing metadata must be accepted'); }
    is_deeply($warn, [], 'library is quiet; caller must guard undef');
  }
};

subtest 'HTML mislabeled as XML is not an empty feed' => sub {
  my ($f, $err, $warn) = attempt('http://feeds.feedburner.com/JohnResig',
    {headers => {'Content-Type' => 'text/xml; charset=utf-8'},
      body => '<html><head><title>Website</title></head></html>'});
  ok(!defined $f, 'Reader rejects HTML despite XML content type');
  is($err, '', 'documented undef for non-feed input');
  is_deeply($warn, [], 'no warnings');
};

subtest 'redirect limit is enforced' => sub {
  my $url = 'http://feeds.feedburner.com/collective-blog';
  my ($f, $err, $warn, $requests) = attempt($url,
    map { +{code => 301, headers => {Location => $url}} } 1 .. 4);
  like($err, qr/Number of redirects exceeded/, 'bounded redirect failure');
  is(scalar @$requests, 4, 'stops after configured default of 3 redirects');
  is_deeply($warn, [], 'no warnings');
};

done_testing;
