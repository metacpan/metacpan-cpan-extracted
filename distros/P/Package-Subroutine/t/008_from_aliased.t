
use Test2::V0;

eval "use aliased 'Package::Subroutine' => 'PS'";
skip_all "Pragma 'aliased' required for this test." if $@;

plan(3);

use Package::Subroutine::Sugar;

package T::P::O;

sub one {};

package T::P::N;

use Test2::V0;

$INC{'T/P/O.pm'} = './t/lib';
eval 'use aliased "T::P::O"';
ok(!$@,'use aliased O') or warn "$@\n";

eval "import from O => qw/code/";
ok(!$@,'import from ok');

ok(T::P::N->can('code'),'import succeeds');


