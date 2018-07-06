#!perl -T

use strict;
use warnings FATAL => 'all';


package My::Test;

use Moo;
with 'Role::Markup::XML';

package main;

use Test::More;

plan tests => 2;

my $obj = My::Test->new;

# meh this is fine for now

my $body = $obj->_XHTML(
    ns     => { dct => 'http://purl.org/dc/terms/' },
    prefix => { foaf => 'http://xmlns.com/foaf/0.1/' },
    lang   => 'en',
);

is($body->namespaceURI, 'http://www.w3.org/1999/xhtml');

is($body->parentNode->getAttribute('xml:lang'), 'en');
