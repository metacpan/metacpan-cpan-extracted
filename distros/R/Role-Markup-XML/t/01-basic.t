#!perl -T

use strict;
use warnings FATAL => 'all';


package My::Test;

use Moo;
with 'Role::Markup::XML';

package main;

use Test::More;

plan tests => 4;


my $obj = My::Test->new;

isa_ok($obj, 'My::Test', 'object checks out');

ok($obj->does('Role::Markup::XML'), 'object does role');

ok('html'      =~ &Role::Markup::XML::QNAME_RE, 'bare matches qname');
ok('html:html' =~ &Role::Markup::XML::QNAME_RE, 'ns matches qname');

#diag(&Role::Markup::XML::QNAME_RE);
