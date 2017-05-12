#!perl
use strict;
use warnings;
use Test::More;
use lib "t/lib";
use SNMP::Extension::PassPersist;


my $module = "SNMP::Extension::PassPersist";
my $common_part = "fatal: An error occurred while executing the backend";
my @cases  = (
    {
        attr => [ backend_init => sub { die "Plonk" } ],
        args => [],
        diag => qr/^$common_part initialisation callback: Plonk/,
    },
    {
        attr => [ backend_collect => sub { die "Plonk" } ],
        args => [],
        diag => qr/^$common_part collecting callback: Plonk/,
    },
);

plan tests => ~~@cases;

for my $case (@cases) {
    my $attr = $case->{attr};
    my $args = $case->{args};
    my $diag = $case->{diag};
    my $object = $module->new(@$attr);
    eval { $object->run() };
    like( $@, $diag, "\$object->run() with \@ARGV=(".join(", ", @$args).")" );
}

