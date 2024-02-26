package RDF::Cowl::Lib::Gen::Class::ObjOneOf;
# ABSTRACT: Private class for RDF::Cowl::ObjOneOf
$RDF::Cowl::Lib::Gen::Class::ObjOneOf::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjOneOf;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_one_of
$ffi->attach( [
 "COWL_WRAP_cowl_obj_one_of"
 => "new" ] =>
	[
		arg "CowlVector" => "inds",
	],
	=> "CowlObjOneOf"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlVector, { name => "inds", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjOneOf::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_one_of_get_inds
$ffi->attach( [
 "COWL_WRAP_cowl_obj_one_of_get_inds"
 => "get_inds" ] =>
	[
		arg "CowlObjOneOf" => "exp",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjOneOf, { name => "exp", },
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

RDF::Cowl::Lib::Gen::Class::ObjOneOf - Private class for RDF::Cowl::ObjOneOf

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
