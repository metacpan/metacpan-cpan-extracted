use strict;
no warnings;

use Test;
use Term::GentooFunctions qw(:all);

plan tests => 1;

my $good = eval {
    # NOTE: We're basically just testing for some problem executing these.
    # We're NOT testing to see if they printed the right things.

    einfo  "test info";
    eerror "test error";
    ewarn  "test warning";

    ebegin "test begin/end (success)";
    #sleep 1;
    eend 1;

    ebegin "test begin/end (fail)";
    #sleep 1;
    eend 0;

    for (qw(test1 test2 test3 test4)) {
        eindent;
        einfo "indent $_";
    }
    eoutdent;
    einfo "back one";
    eoutdent;
    einfo "back two";
    eoutdent for 1 .. 30;
    einfo "back 30";

    ebegin "testing $_";
    $_ = 1;
    eend;

"good" };

ok( "$good$@", "good" );
