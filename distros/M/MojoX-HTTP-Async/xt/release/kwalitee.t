package main;

use strict;
use warnings;
use 5.020;

use Test::More ('import' => [qw/ plan done_testing /]);

BEGIN {
    if (!$ENV{'RELEASE_TESTING'}) {
        plan('skip_all' => 'Skip because RELEASE_TESTING is unset');
    }
}

use Test::Kwalitee qw/ kwalitee_ok /;
kwalitee_ok();
done_testing();

1;
__END__
