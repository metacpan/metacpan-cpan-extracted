#!perl
use strict;
use warnings;
use Test::More;
use lib "t/lib";
use SNMP::Extension::PassPersist;


my $module = "SNMP::Extension::PassPersist";
my @cases  = (
    {
        attr => [],
        diag => qr/^$/,
    },
    {
        attr => [ {} ],
        diag => qr/^$/,
    },
    {
        attr => [ 42 ],
        diag => qr/^error: Odd number of arguments/,
    },
    {
        attr => [ 1, 2, 3 ],
        diag => qr/^error: Odd number of arguments/,
    },
    {   # unknown attributes are ignored
        attr => [ foo => "bar" ],
        diag => qr/^$/,
    },
    {
        attr => [ { foo => "bar" } ],
        diag => qr/^$/,
    },
    {
        attr => [ \my $var ],
        diag => qr/^error: Don't know how to handle scalar reference/,
    },
    {
        attr => [ [] ],
        diag => qr/^error: Don't know how to handle array reference/,
    },
    {
        attr => [ sub {} ],
        diag => qr/^error: Don't know how to handle code reference/,
    },
    {   # checking that code attributes are correctly checked
        attr => [ backend_init => sub {} ],
        diag => qr/^$/,
    },
    {
        attr => [ backend_init => [] ],
        diag => qr/^error: Attribute backend_init must be a code reference/,
    },
    {
        attr => [ backend_init => {} ],
        diag => qr/^error: Attribute backend_init must be a code reference/,
    },
);

plan tests => ~~@cases;

for my $case (@cases) {
    my $attr = $case->{attr};
    my $diag = $case->{diag};
    my $object = eval { $module->new(@$attr) };
    like( $@, $diag, "$module->new(".join(", ", @$attr).")" );
}
