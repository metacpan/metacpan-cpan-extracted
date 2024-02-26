package RDF::Cowl::Lib::Gen::Class::SymTable;
# ABSTRACT: Private class for RDF::Cowl::SymTable
$RDF::Cowl::Lib::Gen::Class::SymTable::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::SymTable;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_sym_table_get_prefix_ns_map
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_get_prefix_ns_map"
 => "get_prefix_ns_map" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "bool" => "reverse",
	],
	=> "CowlTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				BoolLike|InstanceOf["boolean"], { name => "reverse", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::SymTable::get_prefix_ns_map: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sym_table_get_ns
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_get_ns"
 => "get_ns" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "CowlString" => "prefix",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				CowlString, { name => "prefix", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sym_table_get_prefix
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_get_prefix"
 => "get_prefix" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "CowlString" => "ns",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				CowlString, { name => "ns", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sym_table_register_prefix
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_register_prefix"
 => "register_prefix" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "CowlString" => "prefix",
		arg "CowlString" => "ns",
		arg "bool" => "overwrite",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				CowlString, { name => "prefix", },
				CowlString, { name => "ns", },
				BoolLike|InstanceOf["boolean"], { name => "overwrite", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_sym_table_register_prefix_raw
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_register_prefix_raw"
 => "register_prefix_raw" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "UString" => "prefix",
		arg "UString" => "ns",
		arg "bool" => "overwrite",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				UString, { name => "prefix", },
				UString, { name => "ns", },
				BoolLike|InstanceOf["boolean"], { name => "overwrite", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_sym_table_unregister_prefix
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_unregister_prefix"
 => "unregister_prefix" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "CowlString" => "prefix",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				CowlString, { name => "prefix", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_sym_table_unregister_ns
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_unregister_ns"
 => "unregister_ns" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "CowlString" => "ns",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				CowlString, { name => "ns", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_sym_table_merge
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_merge"
 => "merge" ] =>
	[
		arg "CowlSymTable" => "dst",
		arg "CowlSymTable" => "src",
		arg "bool" => "overwrite",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "dst", },
				CowlSymTable, { name => "src", },
				BoolLike|InstanceOf["boolean"], { name => "overwrite", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_sym_table_get_full_iri
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_get_full_iri"
 => "get_full_iri" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "UString" => "ns",
		arg "UString" => "rem",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				UString, { name => "ns", },
				UString, { name => "rem", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::SymTable::get_full_iri: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_sym_table_parse_full_iri
$ffi->attach( [
 "COWL_WRAP_cowl_sym_table_parse_full_iri"
 => "parse_full_iri" ] =>
	[
		arg "CowlSymTable" => "st",
		arg "UString" => "short_iri",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlSymTable, { name => "st", },
				UString, { name => "short_iri", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::SymTable::parse_full_iri: error: returned NULL" unless defined $RETVAL;
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

RDF::Cowl::Lib::Gen::Class::SymTable - Private class for RDF::Cowl::SymTable

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
