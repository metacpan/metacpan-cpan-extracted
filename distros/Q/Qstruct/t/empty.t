use strict;

use Test::More qw/no_plan/;

use Qstruct;

{

Qstruct::load_schema(q{
  qstruct S2 {
    empty @0 int16[];
    some @1 uint32[];
    junk @2 uint64;
    junk_str @3 string;
  }

  qstruct S1 {
    empty1 @0 uint32[];
    empty1_explicit @1 uint32[];
    empty2 @2 string[];
    empty2_explicit @3 string[];
    empty3 @4 blob[];
    empty3_explicit @5 blob[];
    empty4 @6 S2[];
    empty4_explicit @7 S2[];
    some_s2s @8 S2[];
    an_s2 @9 S2;
    an_s2_explicit @10 S2;
  }
});


my $msg1 = S1->encode({
  empty1_explicit => [],
  empty2_explicit => [],
  empty3_explicit => [],
  empty4_explicit => [],
  some_s2s => [
                { empty => [], some => [1, 2, 3], },
                { some => [123], },
              ],
  an_s2_explicit => {},
});

my $obj1 = S1->decode($msg1);
is_deeply($obj1->empty1, []);
is_deeply($obj1->empty1_explicit, []);
is_deeply($obj1->empty2, []);
is_deeply($obj1->empty2_explicit, []);
is_deeply($obj1->empty3, []);
is_deeply($obj1->empty3_explicit, []);
is_deeply($obj1->empty4, []);
is_deeply($obj1->empty4_explicit, []);
is_deeply($obj1->some_s2s->[0]->some, [1,2,3]);
is_deeply($obj1->some_s2s->[0]->empty, []);
is_deeply($obj1->some_s2s->[1]->some, [123]);
is_deeply($obj1->some_s2s->[1]->empty, []);
is_deeply($obj1->an_s2->empty, []);
is_deeply($obj1->an_s2->junk, 0);
is_deeply($obj1->an_s2->junk_str, '');
is_deeply($obj1->an_s2_explicit->empty, []);
is_deeply($obj1->an_s2_explicit->junk, 0);
is_deeply($obj1->an_s2_explicit->junk_str, '');

}
