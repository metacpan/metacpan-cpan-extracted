package RDF::Cowl::Lib::Gen::Class::UTime;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UTime
$RDF::Cowl::Lib::Gen::Class::UTime::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UTime;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# utime_equals
$ffi->attach( [
 "COWL_WRAP_utime_equals"
 => "equals" ] =>
	[
		arg "UTime" => "a",
		arg "UTime" => "b",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UTime, { name => "a", },
				UTime, { name => "b", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # utime_normalize_to_utc
## $ffi->attach( [
##  "COWL_WRAP_utime_normalize_to_utc"
##  => "normalize_to_utc" ] =>
## 	[
## 		arg "UTime" => "time",
## 		arg "int" => "tz_hour",
## 		arg "unsigned" => "tz_minute",
## 	],
## 	=> "void"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UTime, { name => "time", },
## 				Int, { name => "tz_hour", },
## 				Unsigned, { name => "tz_minute", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # utime_to_timestamp
## $ffi->attach( [
##  "COWL_WRAP_utime_to_timestamp"
##  => "to_timestamp" ] =>
## 	[
## 		arg "UTime" => "time",
## 	],
## 	=> "utime_stamp"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UTime, { name => "time", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # utime_from_timestamp
## $ffi->attach( [
##  "COWL_WRAP_utime_from_timestamp"
##  => "from_timestamp" ] =>
## 	[
## 		arg "utime_stamp" => "ts",
## 	],
## 	=> "UTime"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				Utime_stamp, { name => "ts", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # utime_add
## $ffi->attach( [
##  "COWL_WRAP_utime_add"
##  => "add" ] =>
## 	[
## 		arg "UTime" => "time",
## 		arg "long long" => "quantity",
## 		arg "utime_unit" => "unit",
## 	],
## 	=> "void"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UTime, { name => "time", },
## 				Long long, { name => "quantity", },
## 				Utime_unit, { name => "unit", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # utime_diff
## $ffi->attach( [
##  "COWL_WRAP_utime_diff"
##  => "diff" ] =>
## 	[
## 		arg "UTime" => "a",
## 		arg "UTime" => "b",
## 		arg "utime_unit" => "unit",
## 	],
## 	=> "long long"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UTime, { name => "a", },
## 				UTime, { name => "b", },
## 				Utime_unit, { name => "unit", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# utime_to_string
$ffi->attach( [
 "COWL_WRAP_utime_to_string"
 => "to_string" ] =>
	[
		arg "UTime" => "time",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UTime, { name => "time", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# utime_from_string
$ffi->attach( [
 "COWL_WRAP_utime_from_string"
 => "from_string" ] =>
	[
		arg "UTime" => "time",
		arg "UString" => "string",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UTime, { name => "time", },
				UString, { name => "string", },
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

RDF::Cowl::Lib::Gen::Class::UTime - Private class for RDF::Cowl::Ulib::UTime

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
