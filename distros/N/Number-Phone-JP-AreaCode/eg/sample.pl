#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use feature qw/say/;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Number::Phone::JP::AreaCode qw/
    area_code_by_address
    area_code_by_address_prefix_match
    area_code_by_address_fuzzy
    address_by_area_code
/;

address_by_area_code('1456');
address_by_area_code('01456');
area_code_by_address('大阪府東大阪市岩田町');
area_code_by_address_prefix_match('大阪府東大阪市岩田町一丁目');
area_code_by_address_fuzzy('大阪府東大阪市岩田');
