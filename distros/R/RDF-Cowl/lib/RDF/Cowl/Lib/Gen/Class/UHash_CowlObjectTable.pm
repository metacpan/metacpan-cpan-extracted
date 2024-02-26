package RDF::Cowl::Lib::Gen::Class::UHash_CowlObjectTable;
# ABSTRACT: Private class for RDF::Cowl::Ulib::UHash_CowlObjectTable
$RDF::Cowl::Lib::Gen::Class::UHash_CowlObjectTable::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Ulib::UHash_CowlObjectTable;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# uhash_deinit_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_deinit_CowlObjectTable"
 => "hash_deinit" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_copy_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_copy_CowlObjectTable"
 => "hash_copy" ] =>
	[
		arg "UHash_CowlObjectTable" => "src",
		arg "UHash_CowlObjectTable" => "dest",
	],
	=> "uhash_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "src", },
				UHash_CowlObjectTable, { name => "dest", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_copy_as_set_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_copy_as_set_CowlObjectTable"
 => "hash_copy_as_set" ] =>
	[
		arg "UHash_CowlObjectTable" => "src",
		arg "UHash_CowlObjectTable" => "dest",
	],
	=> "uhash_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "src", },
				UHash_CowlObjectTable, { name => "dest", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_clear_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_clear_CowlObjectTable"
 => "hash_clear" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_get_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_get_CowlObjectTable"
 => "hash_get" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "CowlAny" => "key",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				CowlAny, { name => "key", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_resize_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_resize_CowlObjectTable"
 => "hash_resize" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "ulib_uint" => "new_size",
	],
	=> "uhash_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				Ulib_uint, { name => "new_size", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_put_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_put_CowlObjectTable"
 => "hash_put" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "CowlAny" => "key",
		arg "ulib_uint *" => "idx",
	],
	=> "uhash_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				CowlAny, { name => "key", },
				Ulib_uint *, { name => "idx", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_delete_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_delete_CowlObjectTable"
 => "hash_delete" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "ulib_uint" => "x",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				Ulib_uint, { name => "x", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


## # uhmap_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhmap_CowlObjectTable"
##  => "new_hmap" ] =>
## 	[
## 	],
## 	=> "UHash_CowlObjectTable"
## );

# uhmap_get_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhmap_get_CowlObjectTable"
 => "hmap_get" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "CowlAny" => "key",
		arg "CowlAny" => "if_missing",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				CowlAny, { name => "key", },
				CowlAny, { name => "if_missing", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RETVAL = $RETVAL->_REBLESS;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


## # uhmap_set_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhmap_set_CowlObjectTable"
##  => "hmap_set" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny" => "value",
## 		arg "CowlAny **" => "existing",
## 	],
## 	=> "uhash_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny, { name => "value", },
## 				CowlAny **, { name => "existing", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhmap_add_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhmap_add_CowlObjectTable"
##  => "hmap_add" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny" => "value",
## 		arg "CowlAny **" => "existing",
## 	],
## 	=> "uhash_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny, { name => "value", },
## 				CowlAny **, { name => "existing", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhmap_replace_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhmap_replace_CowlObjectTable"
##  => "hmap_replace" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny" => "value",
## 		arg "CowlAny **" => "replaced",
## 	],
## 	=> "bool"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny, { name => "value", },
## 				CowlAny **, { name => "replaced", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhmap_remove_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhmap_remove_CowlObjectTable"
##  => "hmap_remove" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny **" => "r_key",
## 		arg "CowlAny **" => "r_val",
## 	],
## 	=> "bool"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny **, { name => "r_key", },
## 				CowlAny **, { name => "r_val", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhset_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhset_CowlObjectTable"
##  => "new_hset" ] =>
## 	[
## 	],
## 	=> "UHash_CowlObjectTable"
## );

## # uhset_insert_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhset_insert_CowlObjectTable"
##  => "hset_insert" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny **" => "existing",
## 	],
## 	=> "uhash_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny **, { name => "existing", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhset_insert_all_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhset_insert_all_CowlObjectTable"
##  => "hset_insert_all" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny * const *" => "items",
## 		arg "ulib_uint" => "n",
## 	],
## 	=> "uhash_ret"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny * const *, { name => "items", },
## 				Ulib_uint, { name => "n", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhset_replace_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhset_replace_CowlObjectTable"
##  => "hset_replace" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny **" => "replaced",
## 	],
## 	=> "bool"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny **, { name => "replaced", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

## # uhset_remove_CowlObjectTable
## $ffi->attach( [
##  "COWL_WRAP_uhset_remove_CowlObjectTable"
##  => "hset_remove" ] =>
## 	[
## 		arg "UHash_CowlObjectTable" => "h",
## 		arg "CowlAny" => "key",
## 		arg "CowlAny **" => "removed",
## 	],
## 	=> "bool"
## 	=> sub {
## 		my $RETVAL;
## 		my $xs    = shift;
## 
## 
## 		state $signature = signature(
## 			strictness => STRICT,
## 			pos => [
## 				UHash_CowlObjectTable, { name => "h", },
## 				CowlAny, { name => "key", },
## 				CowlAny **, { name => "removed", },
## 			],
## 		);
## 
## 		$RETVAL = $xs->( &$signature );
## 
## 		return $RETVAL;
## 	}
## );

# uhset_is_superset_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_is_superset_CowlObjectTable"
 => "hset_is_superset" ] =>
	[
		arg "UHash_CowlObjectTable" => "h1",
		arg "UHash_CowlObjectTable" => "h2",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h1", },
				UHash_CowlObjectTable, { name => "h2", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhset_union_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_union_CowlObjectTable"
 => "hset_union" ] =>
	[
		arg "UHash_CowlObjectTable" => "h1",
		arg "UHash_CowlObjectTable" => "h2",
	],
	=> "uhash_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h1", },
				UHash_CowlObjectTable, { name => "h2", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhset_intersect_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_intersect_CowlObjectTable"
 => "hset_intersect" ] =>
	[
		arg "UHash_CowlObjectTable" => "h1",
		arg "UHash_CowlObjectTable" => "h2",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h1", },
				UHash_CowlObjectTable, { name => "h2", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhset_hash_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_hash_CowlObjectTable"
 => "hset_hash" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhset_get_any_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_get_any_CowlObjectTable"
 => "hset_get_any" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "CowlAny" => "if_empty",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				CowlAny, { name => "if_empty", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RETVAL = $RETVAL->_REBLESS;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# uhash_is_map_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_is_map_CowlObjectTable"
 => "hash_is_map" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_move_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_move_CowlObjectTable"
 => "hash_move" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
	],
	=> "UHash_CowlObjectTable"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhash_next_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhash_next_CowlObjectTable"
 => "hash_next" ] =>
	[
		arg "UHash_CowlObjectTable" => "h",
		arg "ulib_uint" => "i",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h", },
				Ulib_uint, { name => "i", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# uhset_equals_CowlObjectTable
$ffi->attach( [
 "COWL_WRAP_uhset_equals_CowlObjectTable"
 => "hset_equals" ] =>
	[
		arg "UHash_CowlObjectTable" => "h1",
		arg "UHash_CowlObjectTable" => "h2",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UHash_CowlObjectTable, { name => "h1", },
				UHash_CowlObjectTable, { name => "h2", },
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

RDF::Cowl::Lib::Gen::Class::UHash_CowlObjectTable - Private class for RDF::Cowl::Ulib::UHash_CowlObjectTable

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
