package RDF::Cowl::Lib::Gen::Class::Vector;
# ABSTRACT: Private class for RDF::Cowl::Vector
$RDF::Cowl::Lib::Gen::Class::Vector::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Vector;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_vector
$ffi->attach( [
 "COWL_WRAP_cowl_vector"
 => "new" ] =>
	[
		arg "UVec_CowlObjectPtr" => "vec",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UVec_CowlObjectPtr, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Vector::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_vector_get_data
$ffi->attach( [
 "COWL_WRAP_cowl_vector_get_data"
 => "get_data" ] =>
	[
		arg "CowlVector" => "vec",
	],
	=> "UVec_CowlObjectPtr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlVector, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_vector_count
$ffi->attach( [
 "COWL_WRAP_cowl_vector_count"
 => "count" ] =>
	[
		arg "CowlVector" => "vec",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlVector, { name => "vec", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_vector_get_item
$ffi->attach( [
 "COWL_WRAP_cowl_vector_get_item"
 => "get_item" ] =>
	[
		arg "CowlVector" => "vec",
		arg "ulib_uint" => "idx",
	],
	=> "CowlAny"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlVector, { name => "vec", },
				Ulib_uint, { name => "idx", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RETVAL = $RETVAL->_REBLESS;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_vector_contains
$ffi->attach( [
 "COWL_WRAP_cowl_vector_contains"
 => "contains" ] =>
	[
		arg "CowlVector" => "vec",
		arg "CowlAny" => "object",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlVector, { name => "vec", },
				CowlAny, { name => "object", },
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

RDF::Cowl::Lib::Gen::Class::Vector - Private class for RDF::Cowl::Vector

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
