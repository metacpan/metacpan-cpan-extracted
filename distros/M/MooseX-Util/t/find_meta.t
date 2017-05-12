use strict;
use warnings;

use Test::More;
use MooseX::Util;

{ package TestClass;            use Moose; }
{ package TestClass::NonMoosey;            }

ok !!find_meta  TestClass              => 'yes metaclass';
ok  !find_meta  'TestClass::NonMoosey' => 'no metaclass';

ok !!MooseX::Util::find_meta  TestClass              => 'yes metaclass';
ok  !MooseX::Util::find_meta  'TestClass::NonMoosey' => 'no metaclass';

done_testing;
