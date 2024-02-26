package RDF::Cowl::Lib::Gen::Class::IRI;
# ABSTRACT: Private class for RDF::Cowl::IRI
$RDF::Cowl::Lib::Gen::Class::IRI::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::IRI;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_iri
$ffi->attach( [
 "COWL_WRAP_cowl_iri"
 => "new" ] =>
	[
		arg "CowlString" => "prefix",
		arg "CowlString" => "suffix",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "prefix", },
				CowlString, { name => "suffix", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::IRI::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_iri_from_string
$ffi->attach( [
 "COWL_WRAP_cowl_iri_from_string"
 => "from_string" ] =>
	[
		arg "UString" => "string",
	],
	=> "CowlIRI"
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

		die "RDF::Cowl::IRI::from_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_iri_get_ns
$ffi->attach( [
 "COWL_WRAP_cowl_iri_get_ns"
 => "get_ns" ] =>
	[
		arg "CowlIRI" => "iri",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_iri_get_rem
$ffi->attach( [
 "COWL_WRAP_cowl_iri_get_rem"
 => "get_rem" ] =>
	[
		arg "CowlIRI" => "iri",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_iri_has_rem
$ffi->attach( [
 "COWL_WRAP_cowl_iri_has_rem"
 => "has_rem" ] =>
	[
		arg "CowlIRI" => "iri",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::IRI - Private class for RDF::Cowl::IRI

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
