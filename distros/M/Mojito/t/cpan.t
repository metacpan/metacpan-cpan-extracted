use strictures 1;
use Test::More;
use Mojito::Model::MetaCPAN;
use List::Util qw/first/;
use Data::Dumper::Concise;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

my $api = Mojito::Model::MetaCPAN->new;
my @synopsis = $api->get_synopsis_from_metacpan('Moose');
ok(first { m/package\s+Point/ } @synopsis, 'Moose synopsis line found');

done_testing();