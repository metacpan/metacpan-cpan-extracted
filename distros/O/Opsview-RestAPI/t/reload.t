use 5.12.1;
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use File::Temp;
use File::Basename;
use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);
use ORA_Test;

SKIP: {
    my $ora_test = ORA_Test->new();
    skip $@ if $@;

    $ora_test->login();
    my $result;

    $result = trap {
        $ora_test->rest->reload_pending();
    };
    $trap->did_return("reload_pending was returned");
    $trap->quiet("no further errors on reload_pending");

    note("result: ", $result);

SKIP: {
        # This can happen as other tests do make changes, but should
        # undo them after each test. This still counts as a pending
        # change, however.
        skip "Some pending changes detected", 1 if $result != 0;
        is( $result, 0, "No pending changes" );
    }

    note('Running a reload');
    $result = trap {
        $ora_test->rest->reload();
    };
    $trap->did_return("reload was returned");
    $trap->quiet("no further errors on reload");

    note("Reload result: ", pp($result));

}

done_testing();
__END__
    $result = trap {
        $ora_test->rest->reload_pending();
    };
    $trap->did_return("reload_pending was returned");
    $trap->quiet("no further errors on reload_pending");

SKIP: {
        # This can happen as other tests do make changes, but should
        # undo them after each test. This still counts as a pending
        # change, however.
        skip "Some pending changes detected", 1 if $result != 0;
        is( $result, 0, "No pending changes" );
    }

    $ora_test->logout();
}

done_testing();
