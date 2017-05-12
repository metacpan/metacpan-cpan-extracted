use Mojo::Base -strict;
use Test::More;

use Mojo::Transaction::HTTP;
use Mojo::JSON qw(encode_json);

BEGIN {
    use_ok('Mojo::Snoo::Subreddit');
}

diag('Creating Mojo::Snoo::Subreddit object');
my $perl = Mojo::Snoo::Subreddit->new('perl');
isa_ok($perl, 'Mojo::Snoo::Subreddit');

my @subs = (
    qw(
      links
      links_new
      links_rising
      links_contro
      links_contro_week
      links_contro_month
      links_contro_year
      links_contro_all
      links_top
      links_top_week
      links_top_month
      links_top_year
      links_top_all
      subscribe
      unsubscribe
      )
);
diag(q@Checking can_ok for Mojo::Snoo::Subreddit's methods@);
can_ok($perl, @subs);

cmp_ok($perl->name, 'eq', 'perl', q@Subreddit's name is "perl"@);

done_testing();
