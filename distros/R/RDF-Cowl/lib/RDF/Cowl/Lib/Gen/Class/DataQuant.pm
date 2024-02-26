package RDF::Cowl::Lib::Gen::Class::DataQuant;
# ABSTRACT: Private class for RDF::Cowl::DataQuant
$RDF::Cowl::Lib::Gen::Class::DataQuant::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DataQuant;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_data_quant
$ffi->attach( [
 "COWL_WRAP_cowl_data_quant"
 => "new" ] =>
	[
		arg "CowlQuantType" => "type",
		arg "CowlAnyDataPropExp" => "prop",
		arg "CowlAnyDataRange" => "range",
	],
	=> "CowlDataQuant"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlQuantType, { name => "type", },
				CowlAnyDataPropExp, { name => "prop", },
				CowlAnyDataRange, { name => "range", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DataQuant::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_data_quant_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_data_quant_get_type"
 => "get_type" ] =>
	[
		arg "CowlDataQuant" => "restr",
	],
	=> "CowlQuantType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataQuant, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_data_quant_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_data_quant_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlDataQuant" => "restr",
	],
	=> "CowlDataPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataQuant, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_data_quant_get_range
$ffi->attach( [
 "COWL_WRAP_cowl_data_quant_get_range"
 => "get_range" ] =>
	[
		arg "CowlDataQuant" => "restr",
	],
	=> "CowlDataRange"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataQuant, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::DataQuant - Private class for RDF::Cowl::DataQuant

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
