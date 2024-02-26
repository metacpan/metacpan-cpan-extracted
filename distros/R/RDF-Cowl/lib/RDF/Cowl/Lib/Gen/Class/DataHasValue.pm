package RDF::Cowl::Lib::Gen::Class::DataHasValue;
# ABSTRACT: Private class for RDF::Cowl::DataHasValue
$RDF::Cowl::Lib::Gen::Class::DataHasValue::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DataHasValue;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_data_has_value
$ffi->attach( [
 "COWL_WRAP_cowl_data_has_value"
 => "new" ] =>
	[
		arg "CowlAnyDataPropExp" => "prop",
		arg "CowlLiteral" => "value",
	],
	=> "CowlDataHasValue"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyDataPropExp, { name => "prop", },
				CowlLiteral, { name => "value", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DataHasValue::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_data_has_value_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_data_has_value_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlDataHasValue" => "restr",
	],
	=> "CowlDataPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataHasValue, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_data_has_value_get_value
$ffi->attach( [
 "COWL_WRAP_cowl_data_has_value_get_value"
 => "get_value" ] =>
	[
		arg "CowlDataHasValue" => "restr",
	],
	=> "CowlLiteral"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataHasValue, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::DataHasValue - Private class for RDF::Cowl::DataHasValue

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
