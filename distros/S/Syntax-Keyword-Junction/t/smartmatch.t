use strict;
use warnings;
use Test::More;

use Syntax::Keyword::Junction;
use Syntax::Keyword::Junction::Base;

BEGIN {
  unless (Syntax::Keyword::Junction::Base::_WANT_SMARTMATCH) {
    plan skip_all => "~~ support requires Perl version >= 5.10.1 and < 5.41.0";
  }
}

no if Syntax::Keyword::Junction::Base::_SMARTMATCH_WARNING_CATEGORY,
  warnings => Syntax::Keyword::Junction::Base::_SMARTMATCH_WARNING_CATEGORY;

plan tests => 16;

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
