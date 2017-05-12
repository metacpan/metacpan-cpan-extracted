use 5.010;
use strict;
use warnings;
use Test::More 0.92;
use re qw(regexp_pattern);

my @cases = (
  [ 'Hello' => '^Hello$' => "Plain text" ],
  [ 'He.lo' => '^He.lo$' => "Dot in middle" ],
  [ 'He%lo' => '^He.*lo$' => "Wildcard in middle" ],
  [ 'Hello .' => '^Hello\ .$' => "Trailing dot" ],
  [ '. World' => '^.\ World$' => "Leading dot" ],
  [ 'Hello %' => '^Hello\ .*' => "Trailing wildcard" ],
  [ '% World' => '.*\ World$' => "Leading wildcard" ],
  [ 'He\\.lo' => '^He\.lo$' => "Escaped dot" ],
  [ 'He\\%lo' => '^He\%lo$' => "Escaped wildcard" ],
  [ 'He\\\\o' => '^He\\\\o$' => "Escaped backslash" ],
  [ 'He\\\\.o' => '^He\\\\.o$' => "Backslash and dot" ],
  [ 'He\\\\%o' => '^He\\\\.*o$' => "Backslash and wildcard" ],
  [ 'He\\\\\\.o' => '^He\\\\\.o$' => "Backslashx2 and dot" ],
  [ 'He\\\\\\%o' => '^He\\\\\%o$' => "Backslashx2 and wildcard" ],
  [ 'Hello W.%.d' => '^Hello\\ W..*.d$' => "Mixed dot and wildcard" ],
  [ 'Hello W.\\%.d' => '^Hello\\ W.\\%.d$' => "Mixed dot and escaped wildcard" ],
);

use Regexp::SQL::LIKE qw/to_regexp/;

for my $c ( @cases ) {
  my ( $like, $expect, $label) = @$c;
  my ($pat, $mods) = regexp_pattern(to_regexp($like));
  is ($pat, $expect, $label );
}

done_testing;
