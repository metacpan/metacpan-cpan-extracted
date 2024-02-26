package RDF::Cowl::Lib::Gen::Class::OStream;
# ABSTRACT: Private class for RDF::Cowl::OStream
$RDF::Cowl::Lib::Gen::Class::OStream::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::OStream;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_ostream_get_manager
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_get_manager"
 => "get_manager" ] =>
	[
		arg "CowlOStream" => "stream",
	],
	=> "CowlManager"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ostream_get_sym_table
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_get_sym_table"
 => "get_sym_table" ] =>
	[
		arg "CowlOStream" => "stream",
	],
	=> "CowlSymTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_ostream_write_header
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_write_header"
 => "write_header" ] =>
	[
		arg "CowlOStream" => "stream",
		arg "CowlOntologyHeader" => "header",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
				CowlOntologyHeader, { name => "header", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ostream_write_axiom
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_write_axiom"
 => "write_axiom" ] =>
	[
		arg "CowlOStream" => "stream",
		arg "CowlAnyAxiom" => "axiom",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
				CowlAnyAxiom, { name => "axiom", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ostream_write_footer
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_write_footer"
 => "write_footer" ] =>
	[
		arg "CowlOStream" => "stream",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ostream_write_ontology
$ffi->attach( [
 "COWL_WRAP_cowl_ostream_write_ontology"
 => "write_ontology" ] =>
	[
		arg "CowlOStream" => "stream",
		arg "CowlOntology" => "ontology",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOStream, { name => "stream", },
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

RDF::Cowl::Lib::Gen::Class::OStream - Private class for RDF::Cowl::OStream

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
