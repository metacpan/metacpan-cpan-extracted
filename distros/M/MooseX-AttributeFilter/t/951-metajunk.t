#
use strict;
use warnings;
use Test2::V0;
use Test::Moose;

my $sub = sub { "filtered($_[1])" };

{
    package My::Role1;
    use Moose::Role;
    use MooseX::AttributeFilter;
    
    has kitty => (
        is     => 'rw',
        filter => $sub,
    );
    
    has mitty => (
        is     => 'rw',
    );
}

my @classes;

{
    package My::Class1;
    use Moose;
    with qw< My::Role1 >;
    push @classes, __PACKAGE__;
}

my $r_attr = My::Role1->meta->get_attribute('kitty');
my $c_attr = My::Class1->meta->get_attribute('kitty');
ok( $r_attr->has_filter );
ok( $r_attr->filter == $sub );
ok( $c_attr->has_filter );
ok( $c_attr->filter == $sub );

$r_attr = My::Role1->meta->get_attribute('mitty');
$c_attr = My::Class1->meta->get_attribute('mitty');
ok( not $r_attr->has_filter );
ok( not $c_attr->has_filter );

done_testing;
