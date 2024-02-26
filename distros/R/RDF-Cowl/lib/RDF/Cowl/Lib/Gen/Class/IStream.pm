package RDF::Cowl::Lib::Gen::Class::IStream;
# ABSTRACT: Private class for RDF::Cowl::IStream
$RDF::Cowl::Lib::Gen::Class::IStream::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::IStream;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_istream_get_manager
$ffi->attach( [
 "COWL_WRAP_cowl_istream_get_manager"
 => "get_manager" ] =>
	[
		arg "CowlIStream" => "stream",
	],
	=> "CowlManager"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_istream_get_sym_table
$ffi->attach( [
 "COWL_WRAP_cowl_istream_get_sym_table"
 => "get_sym_table" ] =>
	[
		arg "CowlIStream" => "stream",
	],
	=> "CowlSymTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_istream_handle_iri
$ffi->attach( [
 "COWL_WRAP_cowl_istream_handle_iri"
 => "handle_iri" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlIRI" => "iri",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlIRI, { name => "iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_handle_version
$ffi->attach( [
 "COWL_WRAP_cowl_istream_handle_version"
 => "handle_version" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlIRI" => "version",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlIRI, { name => "version", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_handle_import
$ffi->attach( [
 "COWL_WRAP_cowl_istream_handle_import"
 => "handle_import" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlIRI" => "import",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlIRI, { name => "import", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_handle_annot
$ffi->attach( [
 "COWL_WRAP_cowl_istream_handle_annot"
 => "handle_annot" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlAnnotation" => "annot",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlAnnotation, { name => "annot", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_handle_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_istream_handle_axiom"
 => "handle_axiom" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlAnyAxiom" => "axiom",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlAnyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_process_path
$ffi->attach( [
 "COWL_WRAP_cowl_istream_process_path"
 => "process_path" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "UString" => "path",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				UString, { name => "path", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_process_file
$ffi->attach( [
 "COWL_WRAP_cowl_istream_process_file"
 => "process_file" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "FILE" => "file",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				InstanceOf["FFI::C::File"], { name => "file", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_process_string
$ffi->attach( [
 "COWL_WRAP_cowl_istream_process_string"
 => "process_string" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "UString" => "string",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_process_stream
$ffi->attach( [
 "COWL_WRAP_cowl_istream_process_stream"
 => "process_stream" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "UIStream" => "istream",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				UIStream, { name => "istream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_istream_process_ontology
$ffi->attach( [
 "COWL_WRAP_cowl_istream_process_ontology"
 => "process_ontology" ] =>
	[
		arg "CowlIStream" => "stream",
		arg "CowlOntology" => "ontology",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIStream, { name => "stream", },
				CowlOntology, { name => "ontology", },
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

RDF::Cowl::Lib::Gen::Class::IStream - Private class for RDF::Cowl::IStream

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
