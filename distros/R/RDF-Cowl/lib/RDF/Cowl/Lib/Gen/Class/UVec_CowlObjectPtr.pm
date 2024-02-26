package RDF::Cowl::Lib::Gen::Class::UVec_CowlObjectPtr;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UVec_CowlObjectPtr
$RDF::Cowl::Lib::Gen::Class::UVec_CowlObjectPtr::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UVec_CowlObjectPtr;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# uvec_reserve_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_reserve_CowlObjectPtr"
 => "reserve" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "size",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "size", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_set_range_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_set_range_CowlObjectPtr"
 => "set_range" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "array",
		arg "ulib_uint" => "start",
		arg "ulib_uint" => "n",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "array", },
				Ulib_uint, { name => "start", },
				Ulib_uint, { name => "n", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_copy_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_copy_CowlObjectPtr"
 => "copy" ] =>
	[
		arg "UVec_CowlObjectPtr" => "src",
		arg "UVec_CowlObjectPtr" => "dest",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "src", },
				UVec_CowlObjectPtr, { name => "dest", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_copy_to_array_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_copy_to_array_CowlObjectPtr"
 => "copy_to_array" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "array[]",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "array[]", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_shrink_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_shrink_CowlObjectPtr"
 => "shrink" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_push_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_push_CowlObjectPtr"
 => "push" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_pop_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_pop_CowlObjectPtr"
 => "pop" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_remove_at_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_remove_at_CowlObjectPtr"
 => "remove_at" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "idx",
	],
	=> "CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "idx", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_insert_at_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_insert_at_CowlObjectPtr"
 => "insert_at" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "idx",
		arg "CowlObjectPtr" => "item",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "idx", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_remove_all_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_remove_all_CowlObjectPtr"
 => "remove_all" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_reverse_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_reverse_CowlObjectPtr"
 => "reverse" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_index_of_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_index_of_CowlObjectPtr"
 => "index_of" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_index_of_reverse_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_index_of_reverse_CowlObjectPtr"
 => "index_of_reverse" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_remove_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_remove_CowlObjectPtr"
 => "remove" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_equals_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_equals_CowlObjectPtr"
 => "equals" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "UVec_CowlObjectPtr" => "other",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				UVec_CowlObjectPtr, { name => "other", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_push_unique_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_push_unique_CowlObjectPtr"
 => "push_unique" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uvec_CowlObjectPtr
## $ffi->attach( [
##  "COWL_WRAP_uvec_CowlObjectPtr"
##  => "new" ] =>
## 	[
## 	],
## 	=> "UVec_CowlObjectPtr"
## );

# uvec_data_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_data_CowlObjectPtr"
 => "data" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# uvec_size_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_size_CowlObjectPtr"
 => "size" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_last_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_last_CowlObjectPtr"
 => "last" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_get_range_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_get_range_CowlObjectPtr"
 => "get_range" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "start",
		arg "ulib_uint" => "len",
	],
	=> "UVec_CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "start", },
				Ulib_uint, { name => "len", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_get_range_from_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_get_range_from_CowlObjectPtr"
 => "get_range_from" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "start",
	],
	=> "UVec_CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "start", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_deinit_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_deinit_CowlObjectPtr"
 => "deinit" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_move_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_move_CowlObjectPtr"
 => "move" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "UVec_CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_expand_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_expand_CowlObjectPtr"
 => "expand" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "ulib_uint" => "size",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				Ulib_uint, { name => "size", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_append_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_append_CowlObjectPtr"
 => "append" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "UVec_CowlObjectPtr" => "src",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				UVec_CowlObjectPtr, { name => "src", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_append_array_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_append_array_CowlObjectPtr"
 => "append_array" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "src",
		arg "ulib_uint" => "n",
	],
	=> "uvec_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "src", },
				Ulib_uint, { name => "n", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uvec_contains_CowlObjectPtr
$ffi->attach( [
 "COWL_WRAP_uvec_contains_CowlObjectPtr"
 => "contains" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
		arg "CowlObjectPtr" => "item",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
				CowlObjectPtr, { name => "item", },
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

RDF::Cowl::Lib::Gen::Class::UVec_CowlObjectPtr - Private class for RDF::Cowl::Ulib::UVec_CowlObjectPtr

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
