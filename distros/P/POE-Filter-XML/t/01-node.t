use warnings;
use strict;

use Test::More;

use POE::Filter::XML::Node;

my $node = POE::Filter::XML::Node->new('test');

isa_ok($node, 'POE::Filter::XML::Node');
is($node->nodeName(), 'test', 'Test Node Name');

$node->setAttributes(
    ['to', 'foo@other',
    'from', 'bar@other',
    'type', 'get']
);

is($node->getAttribute('to'), 'foo@other', 'Check attribute one');
is($node->getAttribute('from'), 'bar@other', 'Check attribute two');
is($node->getAttribute('type'), 'get', 'Check attribute three');

for(0..4)
{
    $node->appendTextChild('child1', 'Some Text');
    $node->appendTextChild('child2', 'Some Text2');

}

my $node2 = $node->getSingleChildByTagName('child1');
is(ref($node2), 'POE::Filter::XML::Node', 'Check getSingleChildByTagName returns a proper subclass');

my $hash = $node->getChildrenHash();

is(ref($hash->{'child1'}), 'ARRAY', 'Check children1 are in an array');
is(ref($hash->{'child2'}), 'ARRAY', 'Check children2 are in an array');
is(scalar(@{$hash->{'child1'}}), 5, 'Check there are five children1');
is(scalar(@{$hash->{'child2'}}), 5, 'Check there are five children2');

foreach my $value (values %$hash)
{
    foreach my $child (@$value)
    {
        is(ref($child), 'POE::Filter::XML::Node', 'Test each node is a proper subclass');
    }
}

$node->_set_stream_start(1);
is($node->stream_start(), 1, 'Check stream_start');
is($node->toString(), '<test to="foo@other" from="bar@other" type="get">', 'Check toString() for stream_start');

$node->_set_stream_start(0);
$node->_set_stream_end(1);
is($node->stream_end(), 1, 'Check stream_end');
is($node->toString(), '</test>', 'Check toString() for stream_end');

my $clone = $node->cloneNode(1);
is(ref($clone), 'POE::Filter::XML::Node', 'Check clone returns a proper subclass');

my $clonehash = $clone->getChildrenHash();

foreach my $value (values %$clonehash)
{
    foreach my $child (@$value)
    {
        is(ref($child), 'POE::Filter::XML::Node', 'Test each clone node is a proper subclass');
    }
}

is($clone->stream_start(), $node->stream_start(), 'Check clone semantics for stream_start');
is($clone->stream_end(), $node->stream_end(), 'Check clone semantics for stream_end');

$clone->_set_stream_end(0);
$node->_set_stream_end(0);

is($clone->toString(), $node->toString(), 'Check the clone against the original');

done_testing();
