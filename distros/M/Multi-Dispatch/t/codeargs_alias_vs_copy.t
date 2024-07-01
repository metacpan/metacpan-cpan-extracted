use 5.022;

use warnings;
use experimental 'refaliasing';
use Multi::Dispatch;

use Test::More;

    my %already_called;

    # This version is broken...
    multi call_once_bad (&fn) {
        die "Can't call that twice" if $already_called{\&fn}++;
        goto &fn;
    }

    # This version works as expected...
    multi call_once_good (\&fn) {
        die "Can't call that twice" if $already_called{\&fn}++;
        goto &fn;
    }

    sub foo { pass 'Called foo' }

    call_once_bad(\&foo);
    call_once_bad(\&foo);
    call_once_bad(\&foo);

    call_once_good(\&foo);
    ok !defined eval { call_once_good(\&foo) } => 'Threw exception as expected';

done_testing();


