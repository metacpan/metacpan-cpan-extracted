use strict;
use Test::More;
use Test::Requires {
   'Sub::Exporter' => 0.986,
};
no if $] > 5.017010, warnings => 'experimental::smartmatch';
BEGIN {
    plan skip_all => "~~ support requires v5.10.1" unless $] >= 5.010001;
}

plan tests => 16;

use syntax 'junction';

my $is_1 = sub { $_[0] == 1 };
my $is_2 = sub { $_[0] == 2 };
my $is_5 = sub { $_[0] == 5 };

ok(! (5 ~~  all($is_1,$is_2,$is_5)), '5 !~~  all($is_1,$is_2,$is_5)' );
ok(  (5 ~~  any($is_1,$is_2,$is_5)), '5  ~~  any($is_1,$is_2,$is_5)' );
ok(! (5 ~~ none($is_1,$is_2,$is_5)), '5 !~~ none($is_1,$is_2,$is_5)' );
ok(  (5 ~~  one($is_1,$is_2,$is_5)), '5  ~~  one($is_1,$is_2,$is_5)' );

ok(  (5 ~~  all($is_5,$is_5,$is_5)), '5  ~~  all($is_5,$is_5,$is_5)' );
ok(  (5 ~~  any($is_5,$is_5,$is_5)), '5  ~~  any($is_5,$is_5,$is_5)' );
ok(! (5 ~~ none($is_5,$is_5,$is_5)), '5 !~~ none($is_5,$is_5,$is_5)' );
ok(! (5 ~~  one($is_5,$is_5,$is_5)), '5 !~~  one($is_5,$is_5,$is_5)' );

ok(! (3 ~~  all($is_1,$is_2,$is_5)), '3 !~~  all($is_1,$is_2,$is_5)' );
ok(! (3 ~~  any($is_1,$is_2,$is_5)), '3 !~~  any($is_1,$is_2,$is_5)' );
ok(  (3 ~~ none($is_1,$is_2,$is_5)), '3  ~~ none($is_1,$is_2,$is_5)' );
ok(! (3 ~~  one($is_1,$is_2,$is_5)), '3 !~~  one($is_1,$is_2,$is_5)' );


ok(! (  all(1,2,5) ~~ $is_5), ' all(1,2,5) !~~ $is_5' );
ok(  (  any(1,2,5) ~~ $is_5), ' any(1,2,5)  ~~ $is_5' );
ok(! ( none(1,2,5) ~~ $is_5), 'none(1,2,5) !~~ $is_5' );
ok(  (  one(1,2,5) ~~ $is_5), ' one(1,2,5)  ~~ $is_5' );
