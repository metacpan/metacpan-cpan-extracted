use strict;
use warnings;

use Test::More qw(); 
#Don't import anything or test routines become potential matches during the test

my $CHOOSE_SUB_USED = 0;

use Symbol::Approx::Sub (
    xform => undef,
    match => sub {
        my($sub, @subs) = @_;
        return (0..$#subs);
    },

    choose => sub {
        $CHOOSE_SUB_USED++;
        return 0;
    },
);

sub aa { 'aa' }

sub bb { 'bb' }

b();
c();

Test::More::ok $CHOOSE_SUB_USED,    "Choose sub provided used to choose from matches";
Test::More::is $CHOOSE_SUB_USED, 2, "Choose sub used expected number of times";

Test::More::done_testing();
