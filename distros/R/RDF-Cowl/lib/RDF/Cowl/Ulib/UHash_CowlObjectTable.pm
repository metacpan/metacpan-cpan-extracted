package RDF::Cowl::Ulib::UHash_CowlObjectTable;
# ABSTRACT: [Internal] Raw hash table
$RDF::Cowl::Ulib::UHash_CowlObjectTable::VERSION = '1.0.0';
# UHash(CowlObjectTable)
# See also: CowlTable
use strict;
use warnings;
use namespace::autoclean;
use RDF::Cowl::Lib qw(arg);

my $ffi = RDF::Cowl::Lib->ffi;

require RDF::Cowl::Lib::Gen::Class::UHash_CowlObjectTable unless $RDF::Cowl::no_gen;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Ulib::UHash_CowlObjectTable - [Internal] Raw hash table

=head1 VERSION

version 1.0.0

=head1 GENERATED DOCUMENTATION

See more documentation at:

L<RDF::Cowl::Lib::Gen::Class::UHash_CowlObjectTable>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
