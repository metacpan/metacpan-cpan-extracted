use v5.016;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new->with_roles('+Queued');
$ua->max_redirects(3);
$ua->max_active(5);    # process up to 5 requests at a time

my @big_list_of_urls = map { ($_ % 2) ? "https://bing.com" : "https://google.com" } (0..200);

for my $url (@big_list_of_urls) {
  $ua->get(
    $url,
    sub {
      my ($ua, $tx) = @_;
      if ($tx->success) {
        say "Page at $url is titled: ", $tx->res->dom->at('title')->text;
      }
    }
  );
}

# works with promises, too:
my @p = map {
  $ua->get_p($_)->then(sub { pop->res->dom->at('title')->text })
    ->catch(sub { say "Error: ", @_ })
} @big_list_of_urls;
Mojo::Promise->all(@p)->then(sub { say @$_ for (@_); })->wait;

