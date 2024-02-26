package RDF::Cowl::Lib::Gen::Class::OntologyId;
# ABSTRACT: Private class for RDF::Cowl::OntologyId
$RDF::Cowl::Lib::Gen::Class::OntologyId::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::OntologyId;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_ontology_id_anonymous
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_id_anonymous"
 => "anonymous" ] =>
	[
	],
	=> "CowlOntologyId"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		$RETVAL = $xs->( @_ );

		return $RETVAL;
	}
);


# cowl_ontology_id_equals
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_id_equals"
 => "equals" ] =>
	[
		arg "CowlOntologyId" => "lhs",
		arg "CowlOntologyId" => "rhs",
	],
	=> "bool"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntologyId, { name => "lhs", },
				CowlOntologyId, { name => "rhs", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_ontology_id_hash
$ffi->attach( [
 "COWL_WRAP_cowl_ontology_id_hash"
 => "hash" ] =>
	[
		arg "CowlOntologyId" => "id",
	],
	=> "ulib_uint"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlOntologyId, { name => "id", },
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

RDF::Cowl::Lib::Gen::Class::OntologyId - Private class for RDF::Cowl::OntologyId

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
