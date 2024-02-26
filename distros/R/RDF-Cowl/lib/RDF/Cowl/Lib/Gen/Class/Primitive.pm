package RDF::Cowl::Lib::Gen::Class::Primitive;
# ABSTRACT: Private class for RDF::Cowl::Primitive
$RDF::Cowl::Lib::Gen::Class::Primitive::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Primitive;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_primitive_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_primitive_get_type"
 => "get_type" ] =>
	[
		arg "CowlAnyPrimitive" => "primitive",
	],
	=> "CowlPrimitiveType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyPrimitive, { name => "primitive", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_primitive_is_entity
$ffi->attach( [
 "COWL_WRAP_cowl_primitive_is_entity"
 => "is_entity" ] =>
	[
		arg "CowlAnyPrimitive" => "primitive",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyPrimitive, { name => "primitive", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::Primitive - Private class for RDF::Cowl::Primitive

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
