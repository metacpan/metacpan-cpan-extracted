#
# use_basic.t
#
# Does the module import?
#
use Test::More tests => 1;

BEGIN { use_ok('POSIX::RT::Semaphore'); }
