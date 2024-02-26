package RDF::Cowl::Lib::Gen::Class::HasKeyAxiom;
# ABSTRACT: Private class for RDF::Cowl::HasKeyAxiom
$RDF::Cowl::Lib::Gen::Class::HasKeyAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::HasKeyAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_has_key_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_has_key_axiom"
 => "new" ] =>
	[
		arg "CowlAnyClsExp" => "cls_exp",
		arg "CowlVector" => "obj_props",
		arg "CowlVector" => "data_props",
		arg "opaque" => "annot",
	],
	=> "CowlHasKeyAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyClsExp, { name => "cls_exp", },
				CowlVector, { name => "obj_props", },
				CowlVector, { name => "data_props", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::HasKeyAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_has_key_axiom_get_cls_exp
$ffi->attach( [
 "COWL_WRAP_cowl_has_key_axiom_get_cls_exp"
 => "get_cls_exp" ] =>
	[
		arg "CowlHasKeyAxiom" => "axiom",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlHasKeyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_has_key_axiom_get_obj_props
$ffi->attach( [
 "COWL_WRAP_cowl_has_key_axiom_get_obj_props"
 => "get_obj_props" ] =>
	[
		arg "CowlHasKeyAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlHasKeyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_has_key_axiom_get_data_props
$ffi->attach( [
 "COWL_WRAP_cowl_has_key_axiom_get_data_props"
 => "get_data_props" ] =>
	[
		arg "CowlHasKeyAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlHasKeyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_has_key_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_has_key_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlHasKeyAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlHasKeyAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::HasKeyAxiom - Private class for RDF::Cowl::HasKeyAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
