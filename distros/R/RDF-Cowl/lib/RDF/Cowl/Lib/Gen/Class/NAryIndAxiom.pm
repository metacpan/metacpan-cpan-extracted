package RDF::Cowl::Lib::Gen::Class::NAryIndAxiom;
# ABSTRACT: Private class for RDF::Cowl::NAryIndAxiom
$RDF::Cowl::Lib::Gen::Class::NAryIndAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::NAryIndAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_nary_ind_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_nary_ind_axiom"
 => "new" ] =>
	[
		arg "CowlNAryAxiomType" => "type",
		arg "CowlVector" => "individuals",
		arg "opaque" => "annot",
	],
	=> "CowlNAryIndAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryAxiomType, { name => "type", },
				CowlVector, { name => "individuals", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::NAryIndAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_nary_ind_axiom_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_nary_ind_axiom_get_type"
 => "get_type" ] =>
	[
		arg "CowlNAryIndAxiom" => "axiom",
	],
	=> "CowlNAryAxiomType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryIndAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_nary_ind_axiom_get_individuals
$ffi->attach( [
 "COWL_WRAP_cowl_nary_ind_axiom_get_individuals"
 => "get_individuals" ] =>
	[
		arg "CowlNAryIndAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryIndAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_nary_ind_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_nary_ind_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlNAryIndAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryIndAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::NAryIndAxiom - Private class for RDF::Cowl::NAryIndAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
