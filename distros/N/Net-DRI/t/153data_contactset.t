#!/usr/bin/perl -w

use strict;

use Net::DRI::Data::ContactSet;

use Test::More tests => 3;

can_ok('Net::DRI::Data::ContactSet',qw/new types has_type add del clear set get match has_contact/);

my $s=Net::DRI::Data::ContactSet->new();
isa_ok($s,'Net::DRI::Data::ContactSet');

TODO: {
        local $TODO="tests";
        ok(0);
}

exit 0;
