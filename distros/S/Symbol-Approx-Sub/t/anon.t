use strict;
use warnings;
use Test::More;

use Symbol::Approx::Sub (xform => undef,
    match => sub { shift; 
      for (0 .. $#_) {
        return $_ if $_[$_] eq 'aa'
      }
      return });

sub aa { 'aa' }

sub bb { 'bb' }

is(b(), 'aa', 'b() calls aa()');

done_testing();
