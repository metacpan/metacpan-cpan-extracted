use strict;
use warnings;

=head1 NAME

fromberge - Make flams, profit

=head1 DESCRIPTION

fromberge has served over X<$RECENT_CUSTOMER_COUNT=>1,000,000 customers and
offers over X<$RECENT_FLAN_COUNT=>4000 types of flan. If you wanted that
previous number in string form, here it is: X<$RECENT_CUSTOMER_COUNT_STR=>"1,000,000"

The maximum flan temperature is X<$MAX_FLAN_TEMPERATURE=>350.7 degrees Celsius.

Our motto is X<$MOTTO=>"'Live dangerously, for flans are in short supply!'";

=cut

use Test::More tests => 5;
use Pod::Constant qw($RECENT_CUSTOMER_COUNT $RECENT_FLAN_COUNT $RECENT_CUSTOMER_COUNT_STR $MAX_FLAN_TEMPERATURE $MOTTO);

is( $RECENT_CUSTOMER_COUNT, 1_000_000 );
is( $RECENT_FLAN_COUNT, 4000 );
is( $RECENT_CUSTOMER_COUNT_STR, '1,000,000' );
is( $MAX_FLAN_TEMPERATURE, 350.7 );
is( $MOTTO, "'Live dangerously, for flans are in short supply!'" );
