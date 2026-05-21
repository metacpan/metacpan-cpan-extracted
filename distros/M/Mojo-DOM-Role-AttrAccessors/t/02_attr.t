use Test::More;
use Mojo::DOM;
use strict;

$\ = "\n"; $, = "\t";

my $dom = Mojo::DOM->new('<a href="https://example.com">Example</a>')->with_roles("+AttrAccessors")->at("a");

ok($dom->attr("href") eq $dom->href);

ok $dom->attr('href') eq 'https://example.com', 'attr() still works directly';

$dom->href("#");

ok($dom->attr("href") eq $dom->href, "Setter works");


# setter returns something sensible (the dom object, for chaining)
isa_ok $dom->href('#'), ref $dom, 'setter returns the object';

# chaining actually works
$dom->href('https://example.com')->href('#');
is $dom->href, '#', 'chaining works';

# attribute that does not exist returns undef
is $dom->data_nonexistent, undef, 'missing attribute returns undef';

done_testing()

    
