#! perl
#
# Testing basic functions of iterator.

use strict;
use warnings;
use Test::More tests => 4;

use Template::Flute::Iterator;

my ($cart, $iter);

$cart = [{isbn => '978-0-2016-1622-4', title => 'The Pragmatic Programmer',
          quantity => 1},
         {isbn => '978-1-4302-1833-3',
          title => 'Pro Git', quantity => 1},
 		];

$iter = new Template::Flute::Iterator($cart);
isa_ok($iter, 'Template::Flute::Iterator');

ok($iter->count == 2);

isa_ok($iter->next, 'HASH');

$iter->seed({isbn => '978-0-9779201-5-0', title => 'Modern Perl',
             quantity => 10});

ok($iter->count == 1);
