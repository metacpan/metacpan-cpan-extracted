
use Test::More tests => 3;
use Search::Odeum;

my $doc = Search::Odeum::Document->new('http://search.cpan.org/');

is($doc->uri, 'http://search.cpan.org/');
is($doc->attr('foo', 'bar'), 'bar');
is($doc->attr('foo'), 'bar');

