use 5.008;
use strict;
use warnings;

package Sub::HandlesVia::Toolkit::ObjectPad;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.045';

use Sub::HandlesVia::Mite -all;
extends 'Sub::HandlesVia::Toolkit';

around code_generator_for_attribute => sub {
	my ( $next, $me, $target, $attr ) = ( shift, shift, @_ );
	
	if ( @$attr > 1 or $attr->[0] =~ /^\w/ ) {
		return $me->$next( @_ );
	}
	
	my $attrname = $attr->[0];
	
	use Object::Pad qw( :experimental(mop) );
	use Object::Pad::MetaFunctions ();
	
	my $metaclass = Object::Pad::MOP::Class->for_class($target);
	my $metafield = $metaclass->get_field( $attrname );
	
	my ( $get, $set, $slot, $get_is_lvalue );
	
	if ( $attrname =~ /^\$/ ) {
		
		$get = sub {
			my ( $gen ) = ( shift );
			sprintf( '$metafield->value(%s)', $gen->generate_self );
		};
		$set = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( '( $metafield->value(%s) = %s )', $gen->generate_self, $value );
		};
		$slot = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( '${ Object::Pad::MetaFunctions::ref_field(%s, %s) }', B::perlstring($attrname), $gen->generate_self );
		};
		$get_is_lvalue = false;
	}
	elsif ( $attrname =~ /^\@/ ) {
		
		$get = sub {
			my ( $gen ) = ( shift );
			sprintf( 'Object::Pad::MetaFunctions::ref_field(%s, %s)', B::perlstring($attrname), $gen->generate_self );
		};
		$set = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( '( @{Object::Pad::MetaFunctions::ref_field(%s, %s)} = @{%s} )', B::perlstring($attrname), $gen->generate_self, $value );
		};
		$slot = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( 'Object::Pad::MetaFunctions::ref_field(%s, %s)', B::perlstring($attrname), $gen->generate_self );
		};
		$get_is_lvalue = true;
	}
	elsif ( $attrname =~ /^\%/ ) {
		
		$get = sub {
			my ( $gen ) = ( shift );
			sprintf( 'Object::Pad::MetaFunctions::ref_field(%s, %s)', B::perlstring($attrname), $gen->generate_self );
		};
		$set = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( '( %%{Object::Pad::MetaFunctions::ref_field(%s, %s)} = %%{%s} )', B::perlstring($attrname), $gen->generate_self, $value );
		};
		$slot = sub {
			my ( $gen, $value ) = ( shift, @_ );
			sprintf( 'Object::Pad::MetaFunctions::ref_field(%s, %s)', B::perlstring($attrname), $gen->generate_self );
		};
		$get_is_lvalue = true;
	}
	else {
		croak 'Unexpected name for Object::Pad attribute: %s', $attr;
	}
	
	require Sub::HandlesVia::CodeGenerator;
	return 'Sub::HandlesVia::CodeGenerator'->new(
		toolkit               => $me,
		target                => $target,
		attribute             => $attrname,
		env                   => { '$metafield' => \$metafield },
		method_installer      => sub { $metaclass->add_method( @_ ) }, # compile-time!
		coerce                => false,
		generator_for_get     => $get,
		generator_for_set     => $set,
		generator_for_slot    => $slot,
		get_is_lvalue         => $get_is_lvalue,
		set_checks_isa        => true,
		set_strictly          => false,
		generator_for_default => sub {
			my ( $gen, $handler ) = @_ or die;
			return;
		},
	);
};

1;

