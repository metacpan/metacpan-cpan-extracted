package RDF::Cowl::NAryDataPropAxiom;
# ABSTRACT: Represents an EquivalentDataProperties or DisjointDataProperties axiom in the OWL 2 specification
$RDF::Cowl::NAryDataPropAxiom::VERSION = '1.0.0';
# CowlNAryDataPropAxiom
use strict;
use warnings;
use parent 'RDF::Cowl::Axiom';
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

require RDF::Cowl::Lib::Gen::Class::NAryDataPropAxiom unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::NAryDataPropAxiom - Represents an EquivalentDataProperties or DisjointDataProperties axiom in the OWL 2 specification

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::NAryDataPropAxiom>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
