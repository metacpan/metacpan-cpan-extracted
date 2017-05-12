#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Package::FromData;

my $data = {
    'Test::Package' => {
        constructors => [qw/new init/],
    },
};

create_package_from_data($data);

can_ok 'Test::Package', 'new';
can_ok 'Test::Package', 'init';

my $tp = Test::Package->new;
isa_ok $tp, 'Test::Package', '$tp';

my $tp2 = Test::Package->init;
isa_ok $tp2, 'Test::Package', '$tp2';

is ref $tp,  'Test::Package';
is ref $tp2, 'Test::Package';
