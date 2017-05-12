use Test::More tests => 2;
BEGIN { use_ok('Search::Odeum') };

my $doc = Search::Odeum::Document->new('http://www.example.com/');
isa_ok($doc, 'Search::Odeum::Document');

