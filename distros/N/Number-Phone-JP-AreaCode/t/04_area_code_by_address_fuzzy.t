#!perl

use strict;
use warnings;
use utf8;
use Number::Phone::JP::AreaCode qw/area_code_by_address_fuzzy/;

use Test::More;
use Test::Deep;

cmp_deeply area_code_by_address_fuzzy('大阪府大阪市'), {
    '大阪府大阪市' => {
        area_code         => '6',
        local_code_digits => '4',
    }
};
cmp_deeply area_code_by_address_fuzzy('大阪府大阪市生野区'), {
    '大阪府大阪市' => {
        area_code         => '6',
        local_code_digits => '4',
    }
};
cmp_deeply area_code_by_address_fuzzy('大阪府東大阪市岩田'), {
    '大阪府東大阪市岩田町' => {
        area_code         => '72',
        local_code_digits => '3',
    },
    '大阪府東大阪市岩田町三丁目' => {
        area_code         => '6',
        local_code_digits => '4',
    },
    '大阪府大阪市' => {
        area_code         => '6',
        local_code_digits => '4',
    },
    '大阪府東大阪市' => {
        area_code         => '6',
        local_code_digits => '4',
    },
};

is_deeply area_code_by_address_fuzzy('神奈川県町田市'), {}; # Not exists!!!!

done_testing;

