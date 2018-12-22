use Test::More;
use Test::Exception;

use Symbol::Approx::Sub suggest => 1;

sub aa { 'aa' }

sub bb { 'bb' }

throws_ok { a() } qr/^Cannot find subroutine main::a. Did you mean main::aa\?/, 'Correct exception thrown';

done_testing;
