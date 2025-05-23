package RDF::Cowl::Lib::Gen::Class::NAryData;
# ABSTRACT: Private class for RDF::Cowl::NAryData
$RDF::Cowl::Lib::Gen::Class::NAryData::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::NAryData;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_nary_data
$ffi->attach( [
 "COWL_WRAP_cowl_nary_data"
 => "new" ] =>
	[
		arg "CowlNAryType" => "type",
		arg "CowlVector" => "operands",
	],
	=> "CowlNAryData"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryType, { name => "type", },
				CowlVector, { name => "operands", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::NAryData::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_nary_data_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_nary_data_get_type"
 => "get_type" ] =>
	[
		arg "CowlNAryData" => "range",
	],
	=> "CowlNAryType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryData, { name => "range", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_nary_data_get_operands
$ffi->attach( [
 "COWL_WRAP_cowl_nary_data_get_operands"
 => "get_operands" ] =>
	[
		arg "CowlNAryData" => "range",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlNAryData, { name => "range", },
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

RDF::Cowl::Lib::Gen::Class::NAryData - Private class for RDF::Cowl::NAryData

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
