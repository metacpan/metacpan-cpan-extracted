# TEST THAT LINE NUMBERS ARE PRESERVED AFTER PREPROCESSING

use v5.36;
use strict;
use warnings;


use Test::More;

plan tests => 5;

no feature 'switch';
use Switch::Back;

@ARGV = 'get';

given ( my $par = shift ) {
    is __LINE__, 18;
    when ('url') {
        diag 'parameter passed is "url"';
        fail 'Incorrect branch (url) chosen';
    }
    is __LINE__, 23;
    when ('get') {
        is __LINE__, 25;
        diag 'parameter passed is "get"';
        pass 'Correct branch (get) chosen';
    }

    is __LINE__, 30;
    default {
        fail 'Incorrect branch (default) chosen';
    }
    is __LINE__, 34;
}

is __LINE__, 37;

done_testing();
