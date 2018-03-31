use lib 't/lib';
use Test::More;
use TidierTests;

run_test( <<'RAW', <<'TIDIED', 'GH#12 - Closing Side Comments', 0, '-csc', '-csci=1', '-cscp="## tidy end:"' );
method _trip_attribute_columns {
    1;
}
RAW
method _trip_attribute_columns {
    1;
} ## tidy end: method _trip_attribute_columns
TIDIED

done_testing;

