package RDF::Cowl::Lib::Gen::Class::AnnotProp;
# ABSTRACT: Private class for RDF::Cowl::AnnotProp
$RDF::Cowl::Lib::Gen::Class::AnnotProp::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::AnnotProp;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_annot_prop
$ffi->attach( [
 "COWL_WRAP_cowl_annot_prop"
 => "new" ] =>
	[
		arg "CowlIRI" => "iri",
	],
	=> "CowlAnnotProp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::AnnotProp::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_annot_prop_from_string
$ffi->attach( [
 "COWL_WRAP_cowl_annot_prop_from_string"
 => "from_string" ] =>
	[
		arg "UString" => "string",
	],
	=> "CowlAnnotProp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::AnnotProp::from_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_annot_prop_get_iri
$ffi->attach( [
 "COWL_WRAP_cowl_annot_prop_get_iri"
 => "get_iri" ] =>
	[
		arg "CowlAnnotProp" => "prop",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnnotProp, { name => "prop", },
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

RDF::Cowl::Lib::Gen::Class::AnnotProp - Private class for RDF::Cowl::AnnotProp

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
