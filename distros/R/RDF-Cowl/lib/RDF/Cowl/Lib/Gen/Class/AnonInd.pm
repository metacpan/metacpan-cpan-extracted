package RDF::Cowl::Lib::Gen::Class::AnonInd;
# ABSTRACT: Private class for RDF::Cowl::AnonInd
$RDF::Cowl::Lib::Gen::Class::AnonInd::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::AnonInd;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_anon_ind
$ffi->attach( [
 "COWL_WRAP_cowl_anon_ind"
 => "new" ] =>
	[
		arg "CowlString" => "id",
	],
	=> "CowlAnonInd"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlString, { name => "id", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::AnonInd::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_anon_ind_from_string
$ffi->attach( [
 "COWL_WRAP_cowl_anon_ind_from_string"
 => "from_string" ] =>
	[
		arg "UString" => "string",
	],
	=> "CowlAnonInd"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::AnonInd::from_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_anon_ind_get_id
$ffi->attach( [
 "COWL_WRAP_cowl_anon_ind_get_id"
 => "get_id" ] =>
	[
		arg "CowlAnonInd" => "ind",
	],
	=> "CowlString"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlAnonInd, { name => "ind", },
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

RDF::Cowl::Lib::Gen::Class::AnonInd - Private class for RDF::Cowl::AnonInd

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
