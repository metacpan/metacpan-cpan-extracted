

package Foo;

use strict;


sub new { return bless { },__PACKAGE__; }

sub test {
  return 'test';
}

1;
