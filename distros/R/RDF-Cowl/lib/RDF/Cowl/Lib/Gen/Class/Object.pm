package RDF::Cowl::Lib::Gen::Class::Object;
# ABSTRACT: Private class for RDF::Cowl::Object
$RDF::Cowl::Lib::Gen::Class::Object::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Object;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_retain
# See manual binding definition.


# cowl_release
$ffi->attach( [
 "COWL_WRAP_cowl_release"
 => "release" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_get_type"
 => "get_type" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "CowlObjectType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_entity
$ffi->attach( [
 "COWL_WRAP_cowl_is_entity"
 => "is_entity" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_is_axiom"
 => "is_axiom" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_cls_exp
$ffi->attach( [
 "COWL_WRAP_cowl_is_cls_exp"
 => "is_cls_exp" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_obj_prop_exp
$ffi->attach( [
 "COWL_WRAP_cowl_is_obj_prop_exp"
 => "is_obj_prop_exp" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_data_prop_exp
$ffi->attach( [
 "COWL_WRAP_cowl_is_data_prop_exp"
 => "is_data_prop_exp" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_individual
$ffi->attach( [
 "COWL_WRAP_cowl_is_individual"
 => "is_individual" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_is_data_range
$ffi->attach( [
 "COWL_WRAP_cowl_is_data_range"
 => "is_data_range" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_get_iri
$ffi->attach( [
 "COWL_WRAP_cowl_get_iri"
 => "get_iri" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_to_string
$ffi->attach( [
 "COWL_WRAP_cowl_to_string"
 => "to_string" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Object::to_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_to_debug_string
$ffi->attach( [
 "COWL_WRAP_cowl_to_debug_string"
 => "to_debug_string" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Object::to_debug_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_equals
$ffi->attach( [
 "COWL_WRAP_cowl_equals"
 => "equals" ] =>
	[
		arg "CowlAny" => "lhs",
		arg "CowlAny" => "rhs",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "lhs", },
				CowlAny, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_equals_iri_string
$ffi->attach( [
 "COWL_WRAP_cowl_equals_iri_string"
 => "equals_iri_string" ] =>
	[
		arg "CowlAny" => "object",
		arg "UString" => "iri_str",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
				UString, { name => "iri_str", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_hash
$ffi->attach( [
 "COWL_WRAP_cowl_hash"
 => "hash" ] =>
	[
		arg "CowlAny" => "object",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_iterate_primitives
$ffi->attach( [
 "COWL_WRAP_cowl_iterate_primitives"
 => "iterate_primitives" ] =>
	[
		arg "CowlAny" => "object",
		arg "CowlPrimitiveFlags" => "flags",
		arg "CowlIterator" => "iter",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAny, { name => "object", },
				CowlPrimitiveFlags, { name => "flags", },
				CowlIterator, { name => "iter", },
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

RDF::Cowl::Lib::Gen::Class::Object - Private class for RDF::Cowl::Object

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
