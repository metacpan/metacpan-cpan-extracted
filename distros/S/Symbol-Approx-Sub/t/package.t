use strict;
use warnings;

package X;

use Test::More;

use Symbol::Approx::Sub (xform => undef,
  match => sub { my ($sub, @subs) = @_;
    foreach (0 .. $#subs) {
      return $_
        if $sub eq reverse $subs[$_];
    }
    return;});

sub oof {'yep'}

is(foo(), 'yep', 'foo() calls oof()');

done_testing;
