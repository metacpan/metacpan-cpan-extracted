package RDF::Cowl::Lib::Gen::Class::DatatypeRestr;
# ABSTRACT: Private class for RDF::Cowl::DatatypeRestr
$RDF::Cowl::Lib::Gen::Class::DatatypeRestr::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::DatatypeRestr;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_datatype_restr
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_restr"
 => "new" ] =>
	[
		arg "CowlDatatype" => "datatype",
		arg "CowlVector" => "restrictions",
	],
	=> "CowlDatatypeRestr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatype, { name => "datatype", },
				CowlVector, { name => "restrictions", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::DatatypeRestr::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_datatype_restr_get_datatype
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_restr_get_datatype"
 => "get_datatype" ] =>
	[
		arg "CowlDatatypeRestr" => "restr",
	],
	=> "CowlDatatype"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatypeRestr, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_datatype_restr_get_restrictions
$ffi->attach( [
 "COWL_WRAP_cowl_datatype_restr_get_restrictions"
 => "get_restrictions" ] =>
	[
		arg "CowlDatatypeRestr" => "restr",
	],
	=> "CowlVector"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlDatatypeRestr, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::DatatypeRestr - Private class for RDF::Cowl::DatatypeRestr

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
