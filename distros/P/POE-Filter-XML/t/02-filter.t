use warnings;
use strict;

use Test::More;
use POE::Filter::XML;

my $xml = '<stream><iq from="blah.com" type="result" id="abc123" to="blah@blah.com/foo"><service xmlns="jabber:iq:browse" type="jabber" name="Server" jid="blah.com"/></iq><presence to="blah@blah.com/foo" from="baz@blah.com/bar"/><testnode>THIS IS SOME TEXT</testnode></stream>';

my $filter = POE::Filter::XML->new();

isa_ok($filter, 'POE::Filter::XML');

$filter->get_one_start([$xml]);
while(1)
{
    my $aref = $filter->get_one();

    if(!@$aref)
    {
        last;
    }

    my $node = $aref->[0];

    if( $node->stream_start() )
    {
        pass('Got stream start 1/3');
        is(ref($node), 'POE::Filter::XML::Node', 'Got stream start 2/3');
        is($node->nodeName(), 'stream', 'Got stream start 3/3');
    }

    if( $node->stream_end() )
    {
        pass('Got stream end 1/3');
        is(ref($node), 'POE::Filter::XML::Node', 'Got stream end 2/3');
        is($node->nodeName(), 'stream', 'Got stream end 3/3');
    }

    if( $node->nodeName() eq 'iq' )
    {
        pass('Got iq 1/13');
        is(ref($node), 'POE::Filter::XML::Node', 'Got iq 2/13');
        is($node->getAttribute('from'), 'blah.com', 'Got iq 3/13');
        is($node->getAttribute('type'), 'result', 'Got iq 4/13');
        is($node->getAttribute('to'), 'blah@blah.com/foo', 'Got iq 5/13');
        is($node->getAttribute('id'), 'abc123', 'Got iq 6/13');

        my $child = $node->getSingleChildByTagName('service');
        ok(defined($child), 'Got iq 7/13');
        is(ref($child), 'POE::Filter::XML::Node', 'Got iq 8/13');
        is($child->getAttribute('type'), 'jabber', 'Got iq 9/13');
        is($child->getAttribute('name'), 'Server', 'Got iq 10/13');
        is($child->getAttribute('jid'), 'blah.com', 'Got iq 11/13');
        ok(scalar($child->getNamespaces()), 'Got iq 12/13');
        is(($child->getNamespaces())[0]->value(), 'jabber:iq:browse', 'Got iq 13/13');

    }

    if( $node->nodeName() eq 'presence' )
    {
        pass('Got presence 1/4');
        is(ref($node), 'POE::Filter::XML::Node', 'Got presence 2/4');
        is($node->getAttribute('from'), 'baz@blah.com/bar', 'Got presence 3/4');
        is($node->getAttribute('to'), 'blah@blah.com/foo', 'Got presence 4/4');
    }

    if( $node->nodeName() eq 'testnode' )
    {
        pass('Got testnode 1/3');
        is(ref($node), 'POE::Filter::XML::Node', 'Got testnode 2/3');
        is($node->textContent(), 'THIS IS SOME TEXT', 'Got testnode 3/3');
    }
}

$filter = POE::Filter::XML->new(not_streaming => 1);
$filter->get_one_start([$xml]);
my $node = $filter->get_one()->[0];
is(length($node->toString()), length($xml), 'not_streaming works');

done_testing();
