#!perl -T

use strict;
use warnings FATAL => 'all';


package My::Test;

use Moo;
with 'Role::Markup::XML';

package main;

use Test::More;

plan tests => 10;


my $obj = My::Test->new;

isa_ok($obj, 'My::Test', 'object checks out');

ok($obj->does('Role::Markup::XML'), 'object does role');

ok('html'      =~ &Role::Markup::XML::QNAME_RE, 'bare matches qname');
ok('html:html' =~ &Role::Markup::XML::QNAME_RE, 'ns matches qname');

my $doc = $obj->_DOC;

isa_ok($doc, 'XML::LibXML::Document');

my $html = $obj->_XML(
    doc  => $doc,
    spec => [{ -pi => 'test'}, { -doctype => 'html' }, { -comment => 'wut' },
             { -name => 'html', xmlns => 'http://www.w3.org/1999/xhtml'}],
);

#diag($doc->toString(1));

my $title = $obj->_XML(
    parent => $html,
    spec => { -name => 'head',
              -content => { -name => 'title', -content => 'hi' } },
);

#diag($doc->toString(1));

my $meta = $obj->_XML(
    after => $title->parentNode,
    #spec => { -name => 'svg', xmlns => 'http://www.w3.org/2000/svg' },
    spec => [
        { -comment => 'lol' },
        { -name => 'base', href => 'wat'},
        { href => 'foo' },
        { content => 'wat' },
    ],
);

is($meta->localName, 'meta', 'head elements get the right name');

# diag($doc->toString(1));

# test if the namespace propagates correctly
my $a = $obj->_XML(
    parent => $html,
    spec => { -name => 'body' ,
              -content => [
                  { -name => 'svg', xmlns => 'http://www.w3.org/2000/svg',
                    'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
                    -content => [
                        { -name => 'a', 'xlink:href' => 'foo/' } ] } ] },
);

is($a->getAttributeNode('xlink:href')->namespaceURI,
   'http://www.w3.org/1999/xlink', 'xlink namespace propagates');

my $xpc = $obj->_XPC(svg => 'http://www.w3.org/2000/svg');

isa_ok($xpc, 'XML::LibXML::XPathContext', 'xpc successfully returned');

is($xpc->lookupNs('svg'), 'http://www.w3.org/2000/svg', 'xpc registered ns');

#diag($doc->toString(1));

#my ($htref)  = $xpc->findnodes('//html:title', $doc);
#my ($svgref) = $xpc->findnodes('//*[local-name() = "svg"]', $doc);

#diag($htref);
#diag($svgref->namespaceURI);


my ($svg) = $xpc->findnodes('//svg:svg', $html);

#diag($svg);

ok($svg, 'xpc finds the node');
