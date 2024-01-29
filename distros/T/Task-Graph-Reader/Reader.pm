package Task::Graph::Reader;

use strict;
use warnings;

our $VERSION = 0.04;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Task::Graph::Reader - Install the Graph::Reader modules.

=head1 SYNOPSIS

 cpanm Task::Graph::Reader

=head1 SEE ALSO

=over

=item L<Graph::Reader>

base class for Graph file format readers

=item L<Graph::Reader::Dot>

class for reading a Graph instance from Dot format

=item L<Graph::Reader::Graph6>

read Graph in graph6 or sparse6 format

=item L<Graph::Reader::HTK>

read an HTK lattice in as an instance of Graph

=item L<Graph::Reader::LoadClassHierarchy>

load Graphs from class hierarchies

=item L<Graph::Reader::OID>

Perl class for reading a graph from OID format.

=item L<Graph::Reader::TGF>

Perl class for reading a graph from TGF format.

=item L<Graph::Reader::TGF::CSV>

Perl class for reading a graph from TGF format with CSV labeling.

=item L<Graph::Reader::UnicodeTree>

Perl class for reading a graph from unicode tree text format.

=item L<Graph::Reader::XML>

class for reading a Graph instance from XML

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Task-Graph-Reader>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2024 Michal Josef Špaček

Artistic License

BSD 2-Clause License

=head1 VERSION

0.04

=cut
