package RDF::Cowl::Lib::Gen::Class::DataCard;
# ABSTRACT: Private class for RDF::Cowl::DataCard
$RDF::Cowl::Lib::Gen::Class::DataCard::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DataCard;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_data_card
$ffi->attach( [
 "COWL_WRAP_cowl_data_card"
 => "new" ] =>
	[
		arg "CowlCardType" => "type",
		arg "CowlAnyDataPropExp" => "prop",
		arg "opaque" => "range",
		arg "ulib_uint" => "cardinality",
	],
	=> "CowlDataCard"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlCardType, { name => "type", },
				CowlAnyDataPropExp, { name => "prop", },
				Maybe[ CowlAnyDataRange ], { name => "range", },
				Ulib_uint, { name => "cardinality", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DataCard::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_data_card_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_data_card_get_type"
 => "get_type" ] =>
	[
		arg "CowlDataCard" => "restr",
	],
	=> "CowlCardType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataCard, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_data_card_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_data_card_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlDataCard" => "restr",
	],
	=> "CowlDataPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataCard, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_data_card_get_range
$ffi->attach( [
 "COWL_WRAP_cowl_data_card_get_range"
 => "get_range" ] =>
	[
		arg "CowlDataCard" => "restr",
	],
	=> "CowlDataRange"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataCard, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_data_card_get_cardinality
$ffi->attach( [
 "COWL_WRAP_cowl_data_card_get_cardinality"
 => "get_cardinality" ] =>
	[
		arg "CowlDataCard" => "restr",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDataCard, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::DataCard - Private class for RDF::Cowl::DataCard

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
