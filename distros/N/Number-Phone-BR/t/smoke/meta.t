#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use Number::Phone::BR;

my $class = 'Number::Phone::BR';
my $obj   = $class->new('19 3214 1234');

ok $class->isa('Number::Phone'), 'isa Number::Phone';

ok $obj->can('is_allocated'), 'can is_allocated';
ok $obj->can('is_in_use'), 'can is_in_use';
ok $obj->can('is_geographic'), 'can is_geographic';
ok $obj->can('is_pager'), 'can is_pager';
ok $obj->can('is_ipphone'), 'can is_ipphone';
ok $obj->can('is_isdn'), 'can is_isdn';
ok $obj->can('is_specialrate'), 'can is_specialrate';
ok $obj->can('is_adult'), 'can is_adult';
ok $obj->can('is_international'), 'can is_international';
ok $obj->can('is_personal'), 'can is_personal';
ok $obj->can('is_corporate'), 'can is_corporate';
ok $obj->can('is_government'), 'can is_government';

ok $obj->can('is_tollfree'), 'can is_tollfree';
ok $obj->can('is_network_service'), 'can is_network_service';

ok $obj->can('country'), 'can country';
ok $obj->can('country_code'), 'can country_code';
ok $obj->can('subscriber'), 'can subscriber';
ok $obj->can('areacode'), 'can areacode';
ok $obj->can('areaname'), 'can areaname';
ok $obj->can('is_mobile'), 'can is_mobile';
ok $obj->can('is_fixed_line'), 'can is_fixed_line';
ok $obj->can('is_valid'), 'can is_valid';

done_testing;
