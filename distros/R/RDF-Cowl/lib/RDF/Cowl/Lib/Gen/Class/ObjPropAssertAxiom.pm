package RDF::Cowl::Lib::Gen::Class::ObjPropAssertAxiom;
# ABSTRACT: Private class for RDF::Cowl::ObjPropAssertAxiom
$RDF::Cowl::Lib::Gen::Class::ObjPropAssertAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjPropAssertAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_prop_assert_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom"
 => "new" ] =>
	[
		arg "CowlAnyObjPropExp" => "prop",
		arg "CowlAnyIndividual" => "subject",
		arg "CowlAnyIndividual" => "object",
		arg "opaque" => "annot",
	],
	=> "CowlObjPropAssertAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyObjPropExp, { name => "prop", },
				CowlAnyIndividual, { name => "subject", },
				CowlAnyIndividual, { name => "object", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjPropAssertAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_neg_obj_prop_assert_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_neg_obj_prop_assert_axiom"
 => "cowl_neg_obj_prop_assert_axiom" ] =>
	[
		arg "CowlAnyObjPropExp" => "prop",
		arg "CowlAnyIndividual" => "subject",
		arg "CowlAnyIndividual" => "object",
		arg "opaque" => "annot",
	],
	=> "CowlObjPropAssertAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyObjPropExp, { name => "prop", },
				CowlAnyIndividual, { name => "subject", },
				CowlAnyIndividual, { name => "object", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjPropAssertAxiom::cowl_neg_obj_prop_assert_axiom: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_prop_assert_axiom_is_negative
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom_is_negative"
 => "is_negative" ] =>
	[
		arg "CowlObjPropAssertAxiom" => "axiom",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjPropAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_obj_prop_assert_axiom_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlObjPropAssertAxiom" => "axiom",
	],
	=> "CowlObjPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjPropAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_obj_prop_assert_axiom_get_subject
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom_get_subject"
 => "get_subject" ] =>
	[
		arg "CowlObjPropAssertAxiom" => "axiom",
	],
	=> "CowlIndividual"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjPropAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_obj_prop_assert_axiom_get_object
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom_get_object"
 => "get_object" ] =>
	[
		arg "CowlObjPropAssertAxiom" => "axiom",
	],
	=> "CowlIndividual"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjPropAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_obj_prop_assert_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_obj_prop_assert_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlObjPropAssertAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjPropAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::ObjPropAssertAxiom - Private class for RDF::Cowl::ObjPropAssertAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
