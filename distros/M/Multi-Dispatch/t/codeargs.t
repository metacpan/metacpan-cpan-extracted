use v5.22;
use warnings;

use experimental 'refaliasing';

use Test::More;


use Multi::Dispatch;

sub func { shift() + 42 }

multi foo_copy  ($n,  &f) { return f($n) }
is foo_copy(44, \&func), 86  => 'copied code param';

multi foo_alias ($n, \&f) { return f($n) }
is foo_alias(44, \&func), 86  => 'aliased code param';

multi bar_copy  ( &f) { isnt \&f, \&func  => "copied code param has its own address" }
bar_copy(\&func);

multi bar_alias (\&f) { is   \&f, \&func  => "aliased code param has arg's address"  }
bar_alias(\&func);



done_testing();

