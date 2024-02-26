package RDF::Cowl::Lib::Gen::Class::SubClsAxiom;
# ABSTRACT: Private class for RDF::Cowl::SubClsAxiom
$RDF::Cowl::Lib::Gen::Class::SubClsAxiom::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::SubClsAxiom;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_sub_cls_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_sub_cls_axiom"
 => "new" ] =>
	[
		arg "CowlAnyClsExp" => "sub",
		arg "CowlAnyClsExp" => "super",
		arg "opaque" => "annot",
	],
	=> "CowlSubClsAxiom"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyClsExp, { name => "sub", },
				CowlAnyClsExp, { name => "super", },
				Maybe[ CowlVector ], { name => "annot", default => undef, },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::SubClsAxiom::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_sub_cls_axiom_get_sub
$ffi->attach( [
 "COWL_WRAP_cowl_sub_cls_axiom_get_sub"
 => "get_sub" ] =>
	[
		arg "CowlSubClsAxiom" => "axiom",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubClsAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sub_cls_axiom_get_super
$ffi->attach( [
 "COWL_WRAP_cowl_sub_cls_axiom_get_super"
 => "get_super" ] =>
	[
		arg "CowlSubClsAxiom" => "axiom",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubClsAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sub_cls_axiom_get_annot
$ffi->attach( [
 "COWL_WRAP_cowl_sub_cls_axiom_get_annot"
 => "get_annot" ] =>
	[
		arg "CowlSubClsAxiom" => "axiom",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSubClsAxiom, { name => "axiom", },
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

RDF::Cowl::Lib::Gen::Class::SubClsAxiom - Private class for RDF::Cowl::SubClsAxiom

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
