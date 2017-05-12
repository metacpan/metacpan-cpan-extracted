use strict;
use warnings;

use Test::More tests => 21;

use Moose::Autobox;

ok(Moose::Autobox::SCALAR->does('Moose::Autobox::Scalar'),           '... SCALAR does Moose::Autobox::Scalar');
  ok(Moose::Autobox::SCALAR->does('Moose::Autobox::String'),         '... SCALAR does Moose::Autobox::String');
  ok(Moose::Autobox::SCALAR->does('Moose::Autobox::Number'),         '... SCALAR does Moose::Autobox::Number');
    ok(Moose::Autobox::SCALAR->does('Moose::Autobox::Value'),        '... SCALAR does Moose::Autobox::Value');
        ok(Moose::Autobox::SCALAR->does('Moose::Autobox::Defined'),  '... SCALAR does Moose::Autobox::Defined');
            ok(Moose::Autobox::SCALAR->does('Moose::Autobox::Item'), '... SCALAR does Moose::Autobox::Item');

ok(Moose::Autobox::ARRAY->does('Moose::Autobox::Array'),       '... ARRAY does Moose::Autobox::Array');
  ok(Moose::Autobox::ARRAY->does('Moose::Autobox::List'),      '... ARRAY does Moose::Autobox::List');
  ok(Moose::Autobox::ARRAY->does('Moose::Autobox::Indexed'),   '... ARRAY does Moose::Autobox::Indexed');
  ok(Moose::Autobox::ARRAY->does('Moose::Autobox::Ref'),       '... ARRAY does Moose::Autobox::Ref');
    ok(Moose::Autobox::ARRAY->does('Moose::Autobox::Defined'), '... ARRAY does Moose::Autobox::Defined');
      ok(Moose::Autobox::ARRAY->does('Moose::Autobox::Item'),  '... ARRAY does Moose::Autobox::Item');

ok(Moose::Autobox::HASH->does('Moose::Autobox::Hash'),         '... HASH does Moose::Autobox::Hash');
  ok(Moose::Autobox::HASH->does('Moose::Autobox::Indexed'),    '... HASH does Moose::Autobox::Indexed');
  ok(Moose::Autobox::HASH->does('Moose::Autobox::Ref'),        '... HASH does Moose::Autobox::Ref');
    ok(Moose::Autobox::HASH->does('Moose::Autobox::Defined'),  '... HASH does Moose::Autobox::Defined');
      ok(Moose::Autobox::HASH->does('Moose::Autobox::Item'),   '... HASH does Moose::Autobox::Item');

ok(Moose::Autobox::CODE->does('Moose::Autobox::Code'),         '... CODE does Moose::Autobox::Code');
  ok(Moose::Autobox::CODE->does('Moose::Autobox::Ref'),        '... CODE does Moose::Autobox::Ref');
    ok(Moose::Autobox::CODE->does('Moose::Autobox::Defined'),  '... CODE does Moose::Autobox::Defined');
      ok(Moose::Autobox::CODE->does('Moose::Autobox::Item'),   '... CODE does Moose::Autobox::Item');




