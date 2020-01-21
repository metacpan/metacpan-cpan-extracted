use strict;
use warnings;

## skip Test::Tabs

use lib 't/lib';

{ package Local::Dummy1; use Test::Requires 'Moo'; use Test::Requires 'MooX::TypeTiny'; };

#use Moose ();
#use Moose::Util::TypeConstraints;
#use NoInlineAttribute;
use Test::More;
use Test::Fatal;
#use Test::Moose;

{
    my %handles = (
        abs         => 'abs',
        add         => 'add',
        inc         => [ add => 1 ],
        div         => 'div',
        cut_in_half => [ div => 2 ],
        mod         => 'mod',
        odd         => [ mod => 2 ],
        mul         => 'mul',
        set         => 'set',
        sub         => 'sub',
        dec         => [ sub => 1 ],
    );

    my $name = 'Foo1';

    sub build_class {
        my %attr = @_;
        my %handles_copy = %handles;
         my $class = ++$name;
#        my $class = Moose::Meta::Class->create(
#            $name++,
#            superclasses => ['Moose::Object'],
#        );

        my @traits = 'Number';
#        push @traits, 'NoInlineAttribute'
#            if delete $attr{no_inline};

eval qq{
        package $class;
		  use Moo; use MooX::TypeTiny;
		  use Sub::HandlesVia;
		  use Types::Standard qw(Int);
		  has integer => (
                traits  => [\@traits],
                is      => 'rw',
                isa     => Int,
                default => 5,
                handles => \\%handles_copy,
                clearer => '_clear_integer',
                %attr,
        );
		  sub class_is_lazy { \$attr{lazy} }
		  1;
	  } or die($@);
        return ( $class, \%handles );
    }
}

{
    run_tests(build_class);
    run_tests( build_class( lazy => 1 ) );
    run_tests( build_class( trigger => sub { } ) );
    run_tests( build_class( no_inline => 1 ) );

    run_tests( build_class( isa => Types::Standard::Num()->where(sub {1}) ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

note "Testing class $class";

    can_ok( $class, $_ ) for sort keys %{$handles};

#    with_immutable {
        my $obj = $class->new;

        is( $obj->integer, 5, 'Default to five' );

        is( $obj->add(10), 15, 'add returns new value' );

        is( $obj->integer, 15, 'Add ten for fithteen' );

        like( exception { $obj->add( 10, 2 ) }, qr/number of parameters/, 'add throws an error when 2 arguments are passed' );

        is( $obj->sub(3), 12, 'sub returns new value' );

        is( $obj->integer, 12, 'Subtract three for 12' );

        like( exception { $obj->sub( 10, 2 ) }, qr/number of parameters/, 'sub throws an error when 2 arguments are passed' );

        is( $obj->set(10), 10, 'set returns new value' );

        is( $obj->integer, 10, 'Set to ten' );

        like( exception { $obj->set( 10, 2 ) }, qr/number of parameters/, 'set throws an error when 2 arguments are passed' );

        is( $obj->div(2), 5, 'div returns new value' );

        is( $obj->integer, 5, 'divide by 2' );

        like( exception { $obj->div( 10, 2 ) }, qr/number of parameters/, 'div throws an error when 2 arguments are passed' );

        is( $obj->mul(2), 10, 'mul returns new value' );

        is( $obj->integer, 10, 'multiplied by 2' );

        like( exception { $obj->mul( 10, 2 ) }, qr/number of parameters/, 'mul throws an error when 2 arguments are passed' );

        is( $obj->mod(2), 0, 'mod returns new value' );

        is( $obj->integer, 0, 'Mod by 2' );

        like( exception { $obj->mod( 10, 2 ) }, qr/number of parameters/, 'mod throws an error when 2 arguments are passed' );

        $obj->set(7);

        $obj->mod(5);

        is( $obj->integer, 2, 'Mod by 5' );

        $obj->set(-1);

        is( $obj->abs, 1, 'abs returns new value' );

        like( exception { $obj->abs(10) }, qr/number of parameters/, 'abs throws an error when an argument is passed' );

        is( $obj->integer, 1, 'abs 1' );

        $obj->set(12);

        $obj->inc;

        is( $obj->integer, 13, 'inc 12' );

        $obj->dec;

        is( $obj->integer, 12, 'dec 13' );

        if ( $class->class_is_lazy ) {
            my $obj = $class->new;

            $obj->add(2);

            is( $obj->integer, 7, 'add with lazy default' );

            $obj->_clear_integer;

            $obj->mod(2);

            is( $obj->integer, 1, 'mod with lazy default' );
        }
#    }
#    $class;
}

done_testing;
