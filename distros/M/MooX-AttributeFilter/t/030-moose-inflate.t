#
use strict;
use warnings;
use Test2::V0;
use version;

package MooClass;

use Moo;
use MooX::AttributeFilter;

has attr => (
    is     => 'rw',
    filter => 1,
);

has attr2 => (
    is     => 'rw',
    filter => 'filter2',
);

sub _filter_attr {
    my $this = shift;
    return "filtered($_[0])";
}

sub filter2 {
    my $this = shift;
    return "second($_[0])";
}

package main;

BEGIN {
    my $skipTest = 1;
    eval {
        use Module::Load;
        load Moose;
        load MooseX::AttributeFilter;
        $skipTest = 0;
    };

    skip_all(
        "Cannot test without required Moose and MooseX::AttributeFilter modules"
    ) if $skipTest;
    skip_all("MooseX::AttributeFilter version 0.08 is required")
      unless !$skipTest
      && MooseX::AttributeFilter->VERSION >= version->parse("0.08");
}

eval q{
    package MooseClass;
    use Moose;
    extends qw<MooClass>;
    1;
} or die $@;

for ( 0 .. 1 ) {
    my $obj1 = MooClass->new;
    $obj1->attr("a value");
    is( $obj1->attr, "filtered(a value)", "_filter_attr for attr" );
    $obj1->attr2("3.1415926");
    is( $obj1->attr2, "second(3.1415926)", "filter2 for attr2" );

    my $obj2 = MooseClass->new;
    $obj2->attr("a value");
    is( $obj2->attr, "filtered(a value)", "_filter_attr for attr" );
    $obj2->attr2("3.1415926");
    is( $obj2->attr2, "second(3.1415926)", "filter2 for attr2" );

    MooseClass->meta->make_immutable( inline_constructor => 1 );
}

done_testing;
