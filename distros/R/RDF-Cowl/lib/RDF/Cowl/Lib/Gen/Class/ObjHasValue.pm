package RDF::Cowl::Lib::Gen::Class::ObjHasValue;
# ABSTRACT: Private class for RDF::Cowl::ObjHasValue
$RDF::Cowl::Lib::Gen::Class::ObjHasValue::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjHasValue;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_has_value
$ffi->attach( [
 "COWL_WRAP_cowl_obj_has_value"
 => "new" ] =>
	[
		arg "CowlAnyObjPropExp" => "prop",
		arg "CowlAnyIndividual" => "individual",
	],
	=> "CowlObjHasValue"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyObjPropExp, { name => "prop", },
				CowlAnyIndividual, { name => "individual", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjHasValue::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_has_value_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_obj_has_value_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlObjHasValue" => "exp",
	],
	=> "CowlObjPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjHasValue, { name => "exp", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_obj_has_value_get_ind
$ffi->attach( [
 "COWL_WRAP_cowl_obj_has_value_get_ind"
 => "get_ind" ] =>
	[
		arg "CowlObjHasValue" => "exp",
	],
	=> "CowlIndividual"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjHasValue, { name => "exp", },
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

RDF::Cowl::Lib::Gen::Class::ObjHasValue - Private class for RDF::Cowl::ObjHasValue

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
