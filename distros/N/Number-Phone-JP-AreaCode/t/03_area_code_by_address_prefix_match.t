#!perl

use strict;
use warnings;
use Number::Phone::JP::AreaCode qw/area_code_by_address_prefix_match/;

use Test::More;
use Test::Deep;

cmp_deeply area_code_by_address_prefix_match('東京都練馬区小竹町'), {
    area_code         => '3',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address_prefix_match('北海道函館市石川町123-444'), {
    area_code => '138',
    local_code_digits => '2'
};
cmp_deeply area_code_by_address_prefix_match('京都府乙訓郡大山崎町'), {
    area_code => '75',
    local_code_digits => '3'
};
cmp_deeply area_code_by_address_prefix_match('大阪府東大阪市岩田町'), {
    area_code => '72',
    local_code_digits => '3'
};
cmp_deeply area_code_by_address_prefix_match('大阪府東大阪市岩田町二丁目'), {
    area_code => '72',
    local_code_digits => '3'
};
cmp_deeply area_code_by_address_prefix_match('大阪府東大阪市岩田町三丁目'), {
    area_code => '6',
    local_code_digits => '4'
};
cmp_deeply area_code_by_address_prefix_match('沖縄県宮古島市平良西里'), {
    area_code => '980',
    local_code_digits => '2'
};
cmp_deeply area_code_by_address_prefix_match('岩手県釜石市大字平田大字'), {
    area_code         => '193',
    local_code_digits => '2'
};


ok !area_code_by_address_prefix_match('神奈川県町田市原町田'); # Not exists!!!!

done_testing;

