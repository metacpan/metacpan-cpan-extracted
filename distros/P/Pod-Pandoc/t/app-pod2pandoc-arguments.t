use strict;
use Test::More;
use App::pod2pandoc qw(parse_arguments);

is_deeply
  [ parse_arguments(qw(foo --bar doz --baz --wiki)) ],
  [ ['foo'], { wiki => 1 }, qw(--bar doz --baz) ], 'parse_arguments';

is_deeply
  [ parse_arguments(qw(foo -- doz --baz --wiki)) ],
  [ ['foo'], {}, qw(doz --baz --wiki) ], 'parse_arguments';

done_testing;
