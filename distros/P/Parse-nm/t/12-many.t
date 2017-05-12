
use strict;
use warnings;
use Test::More tests => 65;
use Test::NoWarnings;

use Parse::nm;

my $data = <<EOF;
TestFunc T 0 b
TestVar C 1 1
EOF

our $count;

my $filters = [
    {
        name => qr/TestFunc/,
        type => qr/[A-Z]/,
        action => sub {
            pass "TestFunc action called";
            is ++$count, 1, "TestFunc count";
            is $_[0], "TestFunc", "TestFunc: arg0";
            is $_[1], "T", "TestFunc: arg1";
        }
    },
    {
        name => qr/TestVar/,
        #type => qr/[A-Z]/,
        action => sub {
            pass "TestVar called";
            is ++$count, 2, "TestVar count";
            is $_[0], "TestVar", "TestVar: arg0";
            is $_[1], "C", "TestVar: arg1";
        }
    }
];

sub run_tests(&)
{
    my $code = shift;
    # Run the test 2 times to check there is no state kept
    for my $i (1..2) {
	local $count = 0;
	open my $f, '<', \$data;
	&{$code}($f);
    }
}

# Class interface
run_tests {
    Parse::nm->parse($_[0], filters => $filters);
};

run_tests {
    # No filters => no tests
    Parse::nm->parse($_[0], filters => []);
};

run_tests {
    Parse::nm->parse($_[0], filters => $filters);
};

# Object interface
my $obj = Parse::nm->new(filters => $filters);

run_tests {
    $obj->parse($_[0]);
    $count = 0;
    # Filters are cumulative
    #$obj->parse($_[0], filters => []);
};

my $obj2 = Parse::nm->new(filters => []);
run_tests {
    $obj2->parse($_[0], filters => $filters);
    $count = 0;
    $obj->parse($_[0], filters => []);
};



