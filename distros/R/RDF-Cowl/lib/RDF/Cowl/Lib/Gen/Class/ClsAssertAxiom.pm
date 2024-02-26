package RDF::Cowl::Lib::Gen::Class::ClsAssertAxiom;
# ABSTRACT: Private class for RDF::Cowl::ClsAssertAxiom
$RDF::Cowl::Lib::Gen::Class::ClsAssertAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ClsAssertAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_cls_assert_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_cls_assert_axiom"
 => "new" ] =>
	[
		arg "CowlAnyClsExp" => "exp",
		arg "CowlAnyIndividual" => "ind",
		arg "opaque" => "annot",
	],
	=> "CowlClsAssertAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyClsExp, { name => "exp", },
				CowlAnyIndividual, { name => "ind", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ClsAssertAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_cls_assert_axiom_get_cls_exp
$ffi->attach( [
 "COWL_WRAP_cowl_cls_assert_axiom_get_cls_exp"
 => "get_cls_exp" ] =>
	[
		arg "CowlClsAssertAxiom" => "axiom",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlClsAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_cls_assert_axiom_get_ind
$ffi->attach( [
 "COWL_WRAP_cowl_cls_assert_axiom_get_ind"
 => "get_ind" ] =>
	[
		arg "CowlClsAssertAxiom" => "axiom",
	],
	=> "CowlIndividual"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlClsAssertAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_cls_assert_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_cls_assert_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlClsAssertAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlClsAssertAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::ClsAssertAxiom - Private class for RDF::Cowl::ClsAssertAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
