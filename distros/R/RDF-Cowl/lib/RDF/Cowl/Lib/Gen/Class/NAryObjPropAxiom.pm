package RDF::Cowl::Lib::Gen::Class::NAryObjPropAxiom;
# ABSTRACT: Private class for RDF::Cowl::NAryObjPropAxiom
$RDF::Cowl::Lib::Gen::Class::NAryObjPropAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::NAryObjPropAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_nary_obj_prop_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_nary_obj_prop_axiom"
 => "new" ] =>
	[
		arg "CowlNAryAxiomType" => "type",
		arg "CowlVector" => "props",
		arg "opaque" => "annot",
	],
	=> "CowlNAryObjPropAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryAxiomType, { name => "type", },
				CowlVector, { name => "props", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::NAryObjPropAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_nary_obj_prop_axiom_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_nary_obj_prop_axiom_get_type"
 => "get_type" ] =>
	[
		arg "CowlNAryObjPropAxiom" => "axiom",
	],
	=> "CowlNAryAxiomType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryObjPropAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_nary_obj_prop_axiom_get_props
$ffi->attach( [
 "COWL_WRAP_cowl_nary_obj_prop_axiom_get_props"
 => "get_props" ] =>
	[
		arg "CowlNAryObjPropAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryObjPropAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_nary_obj_prop_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_nary_obj_prop_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlNAryObjPropAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryObjPropAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::NAryObjPropAxiom - Private class for RDF::Cowl::NAryObjPropAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
