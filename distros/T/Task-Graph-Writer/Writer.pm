package Task::Graph::Writer;

# Pragmas.
use strict;
use warnings;

# Version.
our $VERSION = 0.02;

1;

__END__

=pod

=encoding utf8

=head1 NAME

Task::Graph::Writer - Install the Graph::Writer modules.

=head1 SYNOPSIS

 cpanm Task::Graph::Writer

=head1 SEE ALSO

=over

=item L<Graph::Writer>

base class for Graph file format writers

=item L<Graph::Writer::Cytoscape>

Write a directed graph out as Cytoscape competible input file

=item L<Graph::Writer::DSM>

draw graph as a DSM matrix

=item L<Graph::Writer::DSM::HTML>

draw graph as a DSM matrix in HTML format

=item L<Graph::Writer::daVinci>

write out directed graph in daVinci format

=item L<Graph::Writer::Dot>

write out directed graph in Dot format

=item L<Graph::Writer::DrGeo>

Save the graph output DrGeo scheme script.

=item L<Graph::Writer::Graph6>

write Graph in graph6 format

=item L<Graph::Writer::GraphViz>

GraphViz Writer for Graph object

=item L<Graph::Writer::HTK>

write a perl Graph out as an HTK lattice file

=item L<Graph::Writer::Sparse6>

write Graph in sparse6 format

=item L<Graph::Writer::TGXML>

write out directed graph as TouchGraph LinkBrowser XML

=item L<Graph::Writer::VCG>

write out directed graph in VCG format

=item L<Graph::Writer::XML>

write out directed graph as XML

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Task-Graph-Writer>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2015 Michal Špaček
 Artistic License
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
