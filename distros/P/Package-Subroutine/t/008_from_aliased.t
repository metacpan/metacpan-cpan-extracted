
use Test::More;
use strict; use warnings;

eval "use aliased 'Package::Subroutine' => 'PS'";
plan 'skip_all', "Pragma 'aliased' required for this test." if $@;

plan( tests => 3 );

use Package::Subroutine::Sugar;

package T::P::O;

sub one {};

package T::P::N;

$INC{'T/P/O.pm'} = './t/lib';
eval 'use aliased "T::P::O"';
Test::More::ok(!$@,'use aliased O') or warn "$@\n";

eval "import from O => qw/code/";
Test::More::ok(!$@,'import from ok');

Test::More::ok(T::P::N->can('code'),'import succeeds');


