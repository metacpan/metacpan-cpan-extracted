use Mojo::UserAgent;
use Mojo::IOLoop;

my $ua = Mojo::UserAgent->new;
$ua->with_roles('+Queued');
my $mcpan = Mojo::URL->new('https://metacpan.org');
my $search
  = Mojo::URL->new('/search?p=1&q=web+framework&size=500')->to_abs($mcpan);
my %reviews   = ();
my %favorites = ();

sub get_reviews_and_favs {
  my $tx  = pop;
  my $rev = $tx->res->dom->at('span[itemprop=reviewCount]');
  $reviews{$tx->req->url} = ($rev) ? $rev->text : 0;
  my $fav = $tx->res->dom->at('button.favorite span');
  $favorites{$tx->req->url} = ($fav && $fav->text ne '') ? $fav->text : 0;
}

$ua->get_p($search)->then(
  sub {
    my $tx = pop;
    $tx->res->dom->find('.module-result big strong')
      ->grep(sub { 
            $_->text =~ /web\b.*\bframework/i
         })    # make sure the abstract says "web framework"
      ->map(at => 'a')->map('attr', 'href')    # get the link
      ->map(sub { Mojo::URL->new($_)->to_abs($mcpan) }
      )                                          # convert to an absolute URL
      ->map(
      sub {
        $ua->get_p($_)->then(\&get_reviews_and_favs)
          ->catch(sub { print "ERROR: ", @_, "\n" });
      }
    )->each    # another each() to convert the collection to it's elements
  }
)->then(
  sub {
    Mojo::Promise->all(@_)->catch(sub { print "ERROR: ", @_, "\n" });
  }
)->catch(sub { print "ERROR: ", @_, "\n" })->wait();

#Mojo::IOLoop->start unless (Mojo::IOLoop->is_running);

END {
  print "The End, folks\n";
  for my $fwork (
    sort { $favorites{$b} <=> $favorites{$a} || $reviews{$b} <=> $reviews{$a} }
    (keys %reviews))
  {
    print $fwork, " ", $reviews{$fwork}, " reviews, ", $favorites{$fwork},
      " favorites\n";
  }
}
