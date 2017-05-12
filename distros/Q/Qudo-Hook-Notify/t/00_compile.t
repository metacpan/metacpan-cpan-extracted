use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'Qudo::Hook::Notify::Abort';
    use_ok 'Qudo::Hook::Notify::Failed';
    use_ok 'Qudo::Hook::Notify::ReachMaxRetry';
}
