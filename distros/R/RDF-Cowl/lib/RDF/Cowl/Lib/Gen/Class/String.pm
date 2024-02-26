package RDF::Cowl::Lib::Gen::Class::String;
# ABSTRACT: Private class for RDF::Cowl::String
$RDF::Cowl::Lib::Gen::Class::String::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::String;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_string
$ffi->attach( [
 "COWL_WRAP_cowl_string"
 => "new" ] =>
	[
		arg "UString" => "string",
	],
	=> "CowlString"
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

		die "RDF::Cowl::String::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_string_opt
$ffi->attach( [
 "COWL_WRAP_cowl_string_opt"
 => "opt" ] =>
	[
		arg "UString" => "string",
		arg "CowlStringOpts" => "opts",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				CowlStringOpts, { name => "opts", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::String::opt: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_string_empty
$ffi->attach( [
 "COWL_WRAP_cowl_string_empty"
 => "empty" ] =>
	[
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		$RETVAL = $xs->( @_ );

		die "RDF::Cowl::String::empty: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_string_intern
$ffi->attach( [
 "COWL_WRAP_cowl_string_intern"
 => "intern" ] =>
	[
		arg "CowlString" => "string",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_string_release_copying_cstring
$ffi->attach( [
 "COWL_WRAP_cowl_string_release_copying_cstring"
 => "release_copying_cstring" ] =>
	[
		arg "CowlString" => "string",
	],
	=> "string"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_string_get_cstring
# See manual binding definition.


# cowl_string_get_length
$ffi->attach( [
 "COWL_WRAP_cowl_string_get_length"
 => "get_length" ] =>
	[
		arg "CowlString" => "string",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_string_get_raw
$ffi->attach( [
 "COWL_WRAP_cowl_string_get_raw"
 => "get_raw" ] =>
	[
		arg "CowlString" => "string",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # cowl_string_with_format
## $ffi->attach( [
##  "COWL_WRAP_cowl_string_with_format"
##  => "with_format" ] =>
## 	[
## 		arg "string" => "format",
## 		arg "" => "",
## 	],
## 	=> "CowlString"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 		my $class = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				Str, { name => "format", },
## 				, { name => "", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		die "RDF::Cowl::String::with_format: error: returned NULL" unless defined $RETVAL;
## 		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
## 		return $RETVAL;
## 	}
## );

# cowl_string_concat
$ffi->attach( [
 "COWL_WRAP_cowl_string_concat"
 => "concat" ] =>
	[
		arg "CowlString" => "lhs",
		arg "CowlString" => "rhs",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "lhs", },
				CowlString, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::String::concat: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


## # cowl_string_to_int
## $ffi->attach( [
##  "COWL_WRAP_cowl_string_to_int"
##  => "to_int" ] =>
## 	[
## 		arg "CowlString" => "string",
## 		arg "ulib_int *" => "out",
## 		arg "unsigned" => "base",
## 	],
## 	=> "cowl_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				CowlString, { name => "string", },
## 				Ulib_int *, { name => "out", },
## 				Unsigned, { name => "base", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # cowl_string_to_uint
## $ffi->attach( [
##  "COWL_WRAP_cowl_string_to_uint"
##  => "to_uint" ] =>
## 	[
## 		arg "CowlString" => "string",
## 		arg "ulib_uint *" => "out",
## 		arg "unsigned" => "base",
## 	],
## 	=> "cowl_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				CowlString, { name => "string", },
## 				Ulib_uint *, { name => "out", },
## 				Unsigned, { name => "base", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # cowl_string_to_float
## $ffi->attach( [
##  "COWL_WRAP_cowl_string_to_float"
##  => "to_float" ] =>
## 	[
## 		arg "CowlString" => "string",
## 		arg "ulib_float *" => "out",
## 	],
## 	=> "cowl_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				CowlString, { name => "string", },
## 				Ulib_float *, { name => "out", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::String - Private class for RDF::Cowl::String

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
