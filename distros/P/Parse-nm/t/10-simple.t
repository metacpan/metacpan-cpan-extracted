
use strict;
use warnings;
use Test::More tests => 9;
use Test::NoWarnings;

use Parse::nm;

my $data = <<EOF;
TestFunc T 0 b
TestVar C 1 1
EOF

open my $f, '<', \$data or die;

my $count;

Parse::nm->parse($f, filters => [
    {
        name => qr/TestFunc/,
        type => qr/[A-Z]/,
        action => sub {
            pass "action1 called";
            is ++$count, 1;
            is $_[0], "TestFunc", "arg0";
            is $_[1], "T", "arg1";
        }
    },
    {
        name => qr/TestVar/,
        #type => qr/[A-Z]/,
        action => sub {
            pass "action2 called";
            is ++$count, 2;
            is $_[0], "TestVar", "arg0";
            is $_[1], "C", "arg1";
        }
    }
]);
