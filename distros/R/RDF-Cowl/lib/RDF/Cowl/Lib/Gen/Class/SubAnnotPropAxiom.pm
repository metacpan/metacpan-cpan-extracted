package RDF::Cowl::Lib::Gen::Class::SubAnnotPropAxiom;
# ABSTRACT: Private class for RDF::Cowl::SubAnnotPropAxiom
$RDF::Cowl::Lib::Gen::Class::SubAnnotPropAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::SubAnnotPropAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_sub_annot_prop_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_sub_annot_prop_axiom"
 => "new" ] =>
	[
		arg "CowlAnnotProp" => "sub",
		arg "CowlAnnotProp" => "super",
		arg "opaque" => "annot",
	],
	=> "CowlSubAnnotPropAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotProp, { name => "sub", },
				CowlAnnotProp, { name => "super", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::SubAnnotPropAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_sub_annot_prop_axiom_get_sub
$ffi->attach( [
 "COWL_WRAP_cowl_sub_annot_prop_axiom_get_sub"
 => "get_sub" ] =>
	[
		arg "CowlSubAnnotPropAxiom" => "axiom",
	],
	=> "CowlAnnotProp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubAnnotPropAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sub_annot_prop_axiom_get_super
$ffi->attach( [
 "COWL_WRAP_cowl_sub_annot_prop_axiom_get_super"
 => "get_super" ] =>
	[
		arg "CowlSubAnnotPropAxiom" => "axiom",
	],
	=> "CowlAnnotProp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubAnnotPropAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sub_annot_prop_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_sub_annot_prop_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlSubAnnotPropAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubAnnotPropAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::SubAnnotPropAxiom - Private class for RDF::Cowl::SubAnnotPropAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
