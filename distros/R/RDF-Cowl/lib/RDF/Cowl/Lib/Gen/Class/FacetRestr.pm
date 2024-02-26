package RDF::Cowl::Lib::Gen::Class::FacetRestr;
# ABSTRACT: Private class for RDF::Cowl::FacetRestr
$RDF::Cowl::Lib::Gen::Class::FacetRestr::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::FacetRestr;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_facet_restr
$ffi->attach( [
 "COWL_WRAP_cowl_facet_restr"
 => "new" ] =>
	[
		arg "CowlIRI" => "facet",
		arg "CowlLiteral" => "value",
	],
	=> "CowlFacetRestr"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlIRI, { name => "facet", },
				CowlLiteral, { name => "value", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::FacetRestr::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_facet_restr_get_facet
$ffi->attach( [
 "COWL_WRAP_cowl_facet_restr_get_facet"
 => "get_facet" ] =>
	[
		arg "CowlFacetRestr" => "restr",
	],
	=> "CowlIRI"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlFacetRestr, { name => "restr", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_facet_restr_get_value
$ffi->attach( [
 "COWL_WRAP_cowl_facet_restr_get_value"
 => "get_value" ] =>
	[
		arg "CowlFacetRestr" => "restr",
	],
	=> "CowlLiteral"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlFacetRestr, { name => "restr", },
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

RDF::Cowl::Lib::Gen::Class::FacetRestr - Private class for RDF::Cowl::FacetRestr

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
