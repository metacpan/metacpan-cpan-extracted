use strict;
use warnings;

## skip Test::Tabs

use lib 't/lib';

{ package Local::Dummy1; use Test::Requires 'Moose' };

#use Moose ();
#use Moose::Util::TypeConstraints;
#use NoInlineAttribute;
use Test::More;
use Test::Fatal;
#use Test::Moose;

{
    my %handles = (
        illuminate  => 'set',
        darken      => 'unset',
        flip_switch => 'toggle',
        is_dark     => 'not',
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

        my @traits = 'Bool';
#        push @traits, 'NoInlineAttribute'
#            if delete $attr{no_inline};

eval qq{
        package $class;
		  use Moose;
		  use Sub::HandlesVia;
		  use Types::Standard qw(Bool);
		  has is_lit => (
                traits  => [\@traits],
                is      => 'rw',
                isa     => Bool,
                default => 1,
                handles => \\%handles_copy,
                clearer => '_clear_is_lit',
                %attr,
        );
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

    run_tests( build_class( isa => Types::Standard::Bool()->where(sub {1}) ) );
}

sub run_tests {
    my ( $class, $handles ) = @_;

note "Testing class $class";

    can_ok( $class, $_ ) for sort keys %{$handles};

#    with_immutable {
        my $obj = $class->new;

        ok( $obj->illuminate, 'set returns true' );
        ok( $obj->is_lit,   'set is_lit to 1 using ->illuminate' );
        ok( !$obj->is_dark, 'check if is_dark does the right thing' );

        like( exception { $obj->illuminate(1) }, qr/number of parameters/, 'set throws an error when an argument is passed' );

        ok( !$obj->darken, 'unset returns false' );
        ok( !$obj->is_lit, 'set is_lit to 0 using ->darken' );
        ok( $obj->is_dark, 'check if is_dark does the right thing' );

        like( exception { $obj->darken(1) }, qr/number of parameters/, 'unset throws an error when an argument is passed' );

        ok( $obj->flip_switch, 'toggle returns new value' );
        ok( $obj->is_lit,   'toggle is_lit back to 1 using ->flip_switch' );
        ok( !$obj->is_dark, 'check if is_dark does the right thing' );

        like( exception { $obj->flip_switch(1) }, qr/number of parameters/, 'toggle throws an error when an argument is passed' );

        $obj->flip_switch;
        ok( !$obj->is_lit,
            'toggle is_lit back to 0 again using ->flip_switch' );
        ok( $obj->is_dark, 'check if is_dark does the right thing' );
#    }
#    $class;
}

done_testing;
