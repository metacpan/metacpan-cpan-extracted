#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Scalar::Util qw( weaken );

use Resource::Silo;

throws_ok {
    Resource::Silo::Container->new;
} qr(iled to locate), "empty container = no go";

throws_ok {
    silo->ctl->fresh('my_resource_$');
} qr(Illegal.*'.*_\$'), "resource names must be identifiers";

throws_ok {
    silo->ctl->fresh('-target');
} qr(Illegal.*'-target'), "resource names must be identifiers - check -target just in case";

throws_ok {
    silo->ctl->fresh('unknown');
} qr(nonexistent .*'unknown'), "unknown resource = no go";

throws_ok {
    silo->ctl->override('-target' => sub { 1 });
} qr(Attempt to override.*unknown.*'-target'), "can't override poorly named resource";

throws_ok {
    silo->ctl->override('bad_res_name_*' => sub { 1 });
} qr(Attempt to override.*unknown.*'bad_res_name_\*'), "can't override poorly named resource";

throws_ok {
    silo->ctl->override('not_there' => sub { 1 });
} qr(override.*'not_there'), "can't override unknown resource";

done_testing;
