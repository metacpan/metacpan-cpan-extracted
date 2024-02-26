package RDF::Cowl::Lib::Gen::Class::ObjQuant;
# ABSTRACT: Private class for RDF::Cowl::ObjQuant
$RDF::Cowl::Lib::Gen::Class::ObjQuant::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjQuant;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_quant
$ffi->attach( [
 "COWL_WRAP_cowl_obj_quant"
 => "new" ] =>
	[
		arg "CowlQuantType" => "type",
		arg "CowlAnyObjPropExp" => "prop",
		arg "CowlAnyClsExp" => "filler",
	],
	=> "CowlObjQuant"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlQuantType, { name => "type", },
				CowlAnyObjPropExp, { name => "prop", },
				CowlAnyClsExp, { name => "filler", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjQuant::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_quant_get_type
$ffi->attach( [
 "COWL_WRAP_cowl_obj_quant_get_type"
 => "get_type" ] =>
	[
		arg "CowlObjQuant" => "restr",
	],
	=> "CowlQuantType"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjQuant, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_obj_quant_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_obj_quant_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlObjQuant" => "restr",
	],
	=> "CowlObjPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjQuant, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_obj_quant_get_filler
$ffi->attach( [
 "COWL_WRAP_cowl_obj_quant_get_filler"
 => "get_filler" ] =>
	[
		arg "CowlObjQuant" => "restr",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjQuant, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::ObjQuant - Private class for RDF::Cowl::ObjQuant

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
