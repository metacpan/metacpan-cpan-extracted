package RDF::Cowl::Lib::Gen::Class::ObjCompl;
# ABSTRACT: Private class for RDF::Cowl::ObjCompl
$RDF::Cowl::Lib::Gen::Class::ObjCompl::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::ObjCompl;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_obj_compl
$ffi->attach( [
 "COWL_WRAP_cowl_obj_compl"
 => "new" ] =>
	[
		arg "CowlAnyClsExp" => "operand",
	],
	=> "CowlObjCompl"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnyClsExp, { name => "operand", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::ObjCompl::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_obj_compl_get_operand
$ffi->attach( [
 "COWL_WRAP_cowl_obj_compl_get_operand"
 => "get_operand" ] =>
	[
		arg "CowlObjCompl" => "exp",
	],
	=> "CowlClsExp"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlObjCompl, { name => "exp", },
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

RDF::Cowl::Lib::Gen::Class::ObjCompl - Private class for RDF::Cowl::ObjCompl

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
