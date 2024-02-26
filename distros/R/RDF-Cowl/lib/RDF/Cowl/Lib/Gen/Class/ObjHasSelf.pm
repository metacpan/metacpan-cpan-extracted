package RDF::Cowl::Lib::Gen::Class::ObjHasSelf;
# ABSTRACT: Private class for RDF::Cowl::ObjHasSelf
$RDF::Cowl::Lib::Gen::Class::ObjHasSelf::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjHasSelf;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_has_self
$ffi->attach( [
 "COWL_WRAP_cowl_obj_has_self"
 => "new" ] =>
	[
		arg "CowlAnyObjPropExp" => "prop",
	],
	=> "CowlObjHasSelf"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyObjPropExp, { name => "prop", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjHasSelf::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_has_self_get_prop
$ffi->attach( [
 "COWL_WRAP_cowl_obj_has_self_get_prop"
 => "get_prop" ] =>
	[
		arg "CowlObjHasSelf" => "exp",
	],
	=> "CowlObjPropExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjHasSelf, { name => "exp", },
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

RDF::Cowl::Lib::Gen::Class::ObjHasSelf - Private class for RDF::Cowl::ObjHasSelf

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
