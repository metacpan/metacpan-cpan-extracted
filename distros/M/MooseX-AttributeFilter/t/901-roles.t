#
use strict;
use warnings;
use Test2::V0;
use Test::Moose;

{
    package My::Role1;
    use Moose::Role;
    use MooseX::AttributeFilter;
    
    has kitty => (
        is     => 'rw',
        filter => sub { "filtered($_[1])" },
    );
}

{
    package My::Role2;
    use Moose::Role;
    with qw< My::Role1 >;
}

my @classes;

{
    package My::Class1;
    use Moose;
    with qw< My::Role1 >;
    push @classes, __PACKAGE__;
}

{
    package My::Class2;
    use Moose;
    with qw< My::Role2 >;
    push @classes, __PACKAGE__;
}

{
    package My::Class3;
    use Moose;
    with qw< My::Role1 My::Role2 >;
    push @classes, __PACKAGE__;
}

my $mutable = "(mutable)";
with_immutable {
    for my $class (@classes) {
        my $o = $class->new( kitty => "init" );
        like( $o->kitty, "filtered(init)", "$class init $mutable" );
        $o->kitty("val");
        like( $o->kitty, "filtered(val)", "$class accessor $mutable" );
    }
    $mutable = "(immutable)";
} @classes;

done_testing;
