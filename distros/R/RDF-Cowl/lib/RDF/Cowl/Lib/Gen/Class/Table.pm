package RDF::Cowl::Lib::Gen::Class::Table;
# ABSTRACT: Private class for RDF::Cowl::Table
$RDF::Cowl::Lib::Gen::Class::Table::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Table;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_table
$ffi->attach( [
 "COWL_WRAP_cowl_table"
 => "new" ] =>
	[
		arg "UHash_CowlObjectTable" => "table",
	],
	=> "CowlTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "table", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Table::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_table_get_data
$ffi->attach( [
 "COWL_WRAP_cowl_table_get_data"
 => "get_data" ] =>
	[
		arg "CowlTable" => "table",
	],
	=> "UHash_CowlObjectTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlTable, { name => "table", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_table_count
$ffi->attach( [
 "COWL_WRAP_cowl_table_count"
 => "count" ] =>
	[
		arg "CowlTable" => "table",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlTable, { name => "table", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_table_get_value
$ffi->attach( [
 "COWL_WRAP_cowl_table_get_value"
 => "get_value" ] =>
	[
		arg "CowlTable" => "table",
		arg "CowlAny" => "key",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlTable, { name => "table", },
				CowlAny, { name => "key", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RETVAL = $RETVAL->_REBLESS;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_table_get_any
$ffi->attach( [
 "COWL_WRAP_cowl_table_get_any"
 => "get_any" ] =>
	[
		arg "CowlTable" => "table",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlTable, { name => "table", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RETVAL = $RETVAL->_REBLESS;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_table_contains
$ffi->attach( [
 "COWL_WRAP_cowl_table_contains"
 => "contains" ] =>
	[
		arg "CowlTable" => "table",
		arg "CowlAny" => "key",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlTable, { name => "table", },
				CowlAny, { name => "key", },
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

RDF::Cowl::Lib::Gen::Class::Table - Private class for RDF::Cowl::Table

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
