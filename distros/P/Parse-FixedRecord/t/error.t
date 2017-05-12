#!/usr/bin/perl

use strict; use warnings;
use Test::More;
use Test::Fatal;
use FindBin '$Bin';

use lib "$Bin/lib";
use Row::Test;

{
    # my $test_data = 'Fred J Bloggs | 2009-03-17 | 02:03';
    my $test_data = 'Fred J Bloggs | Not a date | 02:03';

    like(exception {
        my $obj = Row::Test->parse( $test_data );
        }, qr/Attribute \(date\) does not pass the type constraint because: Validation failed for 'Date' (?:failed )?with value undef/);
}

{
    my $test_data = 'too short';

    like(exception {
        my $obj = Row::Test->parse( $test_data );
        }, qr/Invalid parse for class Row::Test: input string has length 9, but must have length 34/);
}

{
    my $test_data = 'Fred J Bloggs + 2009-03-17 + 02:03';

    like(exception {
        my $obj = Row::Test->parse( $test_data );
        }, qr/\QInvalid parse on picture ' | ' (got ' + ' at position 13)/);
}

done_testing;
