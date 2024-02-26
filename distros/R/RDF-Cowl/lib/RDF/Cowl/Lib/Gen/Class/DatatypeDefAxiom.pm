package RDF::Cowl::Lib::Gen::Class::DatatypeDefAxiom;
# ABSTRACT: Private class for RDF::Cowl::DatatypeDefAxiom
$RDF::Cowl::Lib::Gen::Class::DatatypeDefAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DatatypeDefAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_datatype_def_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_def_axiom"
 => "new" ] =>
	[
		arg "CowlDatatype" => "dt",
		arg "CowlAnyDataRange" => "range",
		arg "opaque" => "annot",
	],
	=> "CowlDatatypeDefAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatype, { name => "dt", },
				CowlAnyDataRange, { name => "range", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DatatypeDefAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_datatype_def_axiom_get_datatype
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_def_axiom_get_datatype"
 => "get_datatype" ] =>
	[
		arg "CowlDatatypeDefAxiom" => "axiom",
	],
	=> "CowlDatatype"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatypeDefAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_datatype_def_axiom_get_range
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_def_axiom_get_range"
 => "get_range" ] =>
	[
		arg "CowlDatatypeDefAxiom" => "axiom",
	],
	=> "CowlDataRange"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatypeDefAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_datatype_def_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_def_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlDatatypeDefAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatypeDefAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::DatatypeDefAxiom - Private class for RDF::Cowl::DatatypeDefAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
