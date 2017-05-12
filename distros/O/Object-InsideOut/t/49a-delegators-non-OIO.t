# Test that non-OIO-based classes can be delegated to...

use strict;
use warnings;

use Test::More tests => 4;

package Base::Class; {
  sub new { bless {}, shift }

  sub foo { 'base foo' }
  sub bar { 'base bar' }
}


package Other::Base; {
  sub other { 'other base other' }
  sub baz   { 'other base baz'   }
}


package Other; {
    use base 'Other::Base';
}


package Bork; {
    use base 'Base::Class';
    use base 'Other';

    sub bar { 'der bar' }
    sub baz { 'der baz' }
}


package Test; {
    use Object::InsideOut;

    my @handler :Field Handles(Bork::) Default( Bork->new );

    sub baz { 'test baz' }
}


package main;
MAIN:
{
    my $obj = Test->new();

    is $obj->baz(),   'test baz'         => 'Direct call to baz() works';
    is $obj->bar(),   'der bar'          => 'Delegated bar() call works';
    is $obj->foo(),   'base foo'         => 'Delegated foo() call works';
    is $obj->other(), 'other base other' => 'Delegated other() call works';
}

exit(0);

# EOF
