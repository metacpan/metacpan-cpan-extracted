package RDF::Cowl::Lib::Gen::Class::UString;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UString
$RDF::Cowl::Lib::Gen::Class::UString::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UString;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# ustring_size
$ffi->attach( [
 "COWL_WRAP_ustring_size"
 => "size" ] =>
	[
		arg "UString" => "string",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_length
$ffi->attach( [
 "COWL_WRAP_ustring_length"
 => "length" ] =>
	[
		arg "UString" => "string",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_assign
$ffi->attach( [
 "COWL_WRAP_ustring_assign"
 => "assign" ] =>
	[
		arg "string" => "buf",
		arg "size_t" => "length",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
				PositiveOrZeroInt, { name => "length", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_copy
$ffi->attach( [
 "COWL_WRAP_ustring_copy"
 => "copy" ] =>
	[
		arg "string" => "buf",
		arg "size_t" => "length",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
				PositiveOrZeroInt, { name => "length", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_wrap
$ffi->attach( [
 "COWL_WRAP_ustring_wrap"
 => "wrap" ] =>
	[
		arg "string" => "buf",
		arg "size_t" => "length",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
				PositiveOrZeroInt, { name => "length", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring
$ffi->attach( [
 "COWL_WRAP_ustring"
 => "_new" ] =>
	[
		arg "UString" => "string",
		arg "size_t" => "length",
	],
	=> "string"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				PositiveOrZeroInt, { name => "length", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_assign_buf
$ffi->attach( [
 "COWL_WRAP_ustring_assign_buf"
 => "assign_buf" ] =>
	[
		arg "string" => "buf",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_copy_buf
$ffi->attach( [
 "COWL_WRAP_ustring_copy_buf"
 => "copy_buf" ] =>
	[
		arg "string" => "buf",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_wrap_buf
$ffi->attach( [
 "COWL_WRAP_ustring_wrap_buf"
 => "wrap_buf" ] =>
	[
		arg "string" => "buf",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				Str, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_dup
$ffi->attach( [
 "COWL_WRAP_ustring_dup"
 => "dup" ] =>
	[
		arg "UString" => "string",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # ustring_with_format
## $ffi->attach( [
##  "COWL_WRAP_ustring_with_format"
##  => "with_format" ] =>
## 	[
## 		arg "string" => "format",
## 		arg "" => "",
## 	],
## 	=> "UString"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
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
## 		return $RETVAL;
## 	}
## );

## # ustring_with_format_list
## $ffi->attach( [
##  "COWL_WRAP_ustring_with_format_list"
##  => "with_format_list" ] =>
## 	[
## 		arg "string" => "format",
## 		arg "va_list" => "args",
## 	],
## 	=> "UString"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				Str, { name => "format", },
## 				Va_list, { name => "args", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# ustring_concat
$ffi->attach( [
 "COWL_WRAP_ustring_concat"
 => "concat" ] =>
	[
		arg "UString" => "strings",
		arg "ulib_uint" => "count",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "strings", },
				Ulib_uint, { name => "count", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_join
$ffi->attach( [
 "COWL_WRAP_ustring_join"
 => "join" ] =>
	[
		arg "UString" => "strings",
		arg "ulib_uint" => "count",
		arg "UString" => "sep",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "strings", },
				Ulib_uint, { name => "count", },
				UString, { name => "sep", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_repeating
$ffi->attach( [
 "COWL_WRAP_ustring_repeating"
 => "repeating" ] =>
	[
		arg "UString" => "string",
		arg "ulib_uint" => "times",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				Ulib_uint, { name => "times", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_is_upper
$ffi->attach( [
 "COWL_WRAP_ustring_is_upper"
 => "is_upper" ] =>
	[
		arg "UString" => "string",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_is_lower
$ffi->attach( [
 "COWL_WRAP_ustring_is_lower"
 => "is_lower" ] =>
	[
		arg "UString" => "string",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_to_upper
$ffi->attach( [
 "COWL_WRAP_ustring_to_upper"
 => "to_upper" ] =>
	[
		arg "UString" => "string",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_to_lower
$ffi->attach( [
 "COWL_WRAP_ustring_to_lower"
 => "to_lower" ] =>
	[
		arg "UString" => "string",
	],
	=> "UString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_index_of
$ffi->attach( [
 "COWL_WRAP_ustring_index_of"
 => "index_of" ] =>
	[
		arg "UString" => "string",
		arg "char" => "needle",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				StrMatch[qr{\A.\z}], { name => "needle", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_index_of_last
$ffi->attach( [
 "COWL_WRAP_ustring_index_of_last"
 => "index_of_last" ] =>
	[
		arg "UString" => "string",
		arg "char" => "needle",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				StrMatch[qr{\A.\z}], { name => "needle", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_find
$ffi->attach( [
 "COWL_WRAP_ustring_find"
 => "find" ] =>
	[
		arg "UString" => "string",
		arg "UString" => "needle",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				UString, { name => "needle", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_find_last
$ffi->attach( [
 "COWL_WRAP_ustring_find_last"
 => "find_last" ] =>
	[
		arg "UString" => "string",
		arg "UString" => "needle",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				UString, { name => "needle", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_starts_with
$ffi->attach( [
 "COWL_WRAP_ustring_starts_with"
 => "starts_with" ] =>
	[
		arg "UString" => "string",
		arg "UString" => "prefix",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				UString, { name => "prefix", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_ends_with
$ffi->attach( [
 "COWL_WRAP_ustring_ends_with"
 => "ends_with" ] =>
	[
		arg "UString" => "string",
		arg "UString" => "suffix",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
				UString, { name => "suffix", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_equals
$ffi->attach( [
 "COWL_WRAP_ustring_equals"
 => "equals" ] =>
	[
		arg "UString" => "lhs",
		arg "UString" => "rhs",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "lhs", },
				UString, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_precedes
$ffi->attach( [
 "COWL_WRAP_ustring_precedes"
 => "precedes" ] =>
	[
		arg "UString" => "lhs",
		arg "UString" => "rhs",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "lhs", },
				UString, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_compare
$ffi->attach( [
 "COWL_WRAP_ustring_compare"
 => "compare" ] =>
	[
		arg "UString" => "lhs",
		arg "UString" => "rhs",
	],
	=> "int"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "lhs", },
				UString, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_hash
$ffi->attach( [
 "COWL_WRAP_ustring_hash"
 => "hash" ] =>
	[
		arg "UString" => "string",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # ustring_to_int
## $ffi->attach( [
##  "COWL_WRAP_ustring_to_int"
##  => "to_int" ] =>
## 	[
## 		arg "UString" => "string",
## 		arg "ulib_int *" => "out",
## 		arg "unsigned" => "base",
## 	],
## 	=> "ulib_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UString, { name => "string", },
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

## # ustring_to_uint
## $ffi->attach( [
##  "COWL_WRAP_ustring_to_uint"
##  => "to_uint" ] =>
## 	[
## 		arg "UString" => "string",
## 		arg "ulib_uint *" => "out",
## 		arg "unsigned" => "base",
## 	],
## 	=> "ulib_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UString, { name => "string", },
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

## # ustring_to_float
## $ffi->attach( [
##  "COWL_WRAP_ustring_to_float"
##  => "to_float" ] =>
## 	[
## 		arg "UString" => "string",
## 		arg "ulib_float *" => "out",
## 	],
## 	=> "ulib_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UString, { name => "string", },
## 				Ulib_float *, { name => "out", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# ustring_deinit
$ffi->attach( [
 "COWL_WRAP_ustring_deinit"
 => "deinit" ] =>
	[
		arg "UString" => "string",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_deinit_return_data
$ffi->attach( [
 "COWL_WRAP_ustring_deinit_return_data"
 => "deinit_return_data" ] =>
	[
		arg "UString" => "string",
	],
	=> "string"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_is_null
$ffi->attach( [
 "COWL_WRAP_ustring_is_null"
 => "is_null" ] =>
	[
		arg "UString" => "string",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# ustring_is_empty
$ffi->attach( [
 "COWL_WRAP_ustring_is_empty"
 => "is_empty" ] =>
	[
		arg "UString" => "string",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
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

RDF::Cowl::Lib::Gen::Class::UString - Private class for RDF::Cowl::Ulib::UString

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
