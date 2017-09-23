#!perl -T

use strict;
use warnings FATAL => 'all';

package My::Test;

use Moo;
with 'Role::MimeInfo';

package main;

use Test::More;

plan tests => 4;

my $obj = My::Test->new;

can_ok($obj, 'mimetype');

can_ok($obj, 'mimetype_isa');

ok($obj->mimetype_isa('text/html', 'text/plain'), 'out of the box works');

ok($obj->mimetype_isa('text/plain', 'text/plain'), 'new behaviour');
