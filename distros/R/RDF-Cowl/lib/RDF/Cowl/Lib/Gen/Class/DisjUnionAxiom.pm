package RDF::Cowl::Lib::Gen::Class::DisjUnionAxiom;
# ABSTRACT: Private class for RDF::Cowl::DisjUnionAxiom
$RDF::Cowl::Lib::Gen::Class::DisjUnionAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DisjUnionAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_disj_union_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_disj_union_axiom"
 => "new" ] =>
	[
		arg "CowlClass" => "cls",
		arg "CowlVector" => "disjoints",
		arg "opaque" => "annot",
	],
	=> "CowlDisjUnionAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlClass, { name => "cls", },
				CowlVector, { name => "disjoints", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DisjUnionAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_disj_union_axiom_get_class
$ffi->attach( [
 "COWL_WRAP_cowl_disj_union_axiom_get_class"
 => "get_class" ] =>
	[
		arg "CowlDisjUnionAxiom" => "axiom",
	],
	=> "CowlClass"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDisjUnionAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_disj_union_axiom_get_disjoints
$ffi->attach( [
 "COWL_WRAP_cowl_disj_union_axiom_get_disjoints"
 => "get_disjoints" ] =>
	[
		arg "CowlDisjUnionAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDisjUnionAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_disj_union_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_disj_union_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlDisjUnionAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDisjUnionAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::DisjUnionAxiom - Private class for RDF::Cowl::DisjUnionAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
