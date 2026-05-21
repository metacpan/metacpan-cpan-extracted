use Test::More;
use Mojo::DOM;
use strict;

$\ = "\n"; $, = "\t";

my $dom = Mojo::DOM->new('<a href="https://example.com">Example</a>')->with_roles("+AttrAccessors")->at("a");

ok($dom->attr("href") eq $dom->href);

done_testing()
