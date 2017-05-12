#!perl

use strict;
use warnings;
use Number::Phone::JP::AreaCode qw/area_code_by_address/;

use Test::More;
use Test::Deep;

cmp_deeply area_code_by_address('東京都練馬区'), {
    area_code         => '3',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address('北海道函館市'), {
    area_code         => '138',
    local_code_digits => '2'
};
cmp_deeply area_code_by_address('京都府乙訓郡'), {
    area_code         => '75',
    local_code_digits => '3'
};
cmp_deeply area_code_by_address('大阪府東大阪市岩田町'), {
    area_code         => '72',
    local_code_digits => '3'
};
cmp_deeply area_code_by_address('大阪府東大阪市岩田町三丁目'), {
    area_code         => '6',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address('大阪府東大阪市岩田町3丁目'), {
    area_code         => '6',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address('大阪府東大阪市岩田町３丁目'), {
    area_code         => '6',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address('沖縄県宮古島市'), {
    area_code         => '980',
    local_code_digits => '2'
};

ok !area_code_by_address('神奈川県町田市'); # Not exists!!!!

done_testing;

