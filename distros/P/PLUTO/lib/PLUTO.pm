package PLUTO;

use strict;
use warnings;

use strict 'vars';

# add versioning to this module
use vars qw{$VERSION};

BEGIN {
    use vars qw{@ISA @EXPORT @EXPORT_OK};
    $VERSION = 0.30;
    *PLUTO::VERSION = *VERSION;
}

1;

__END__

=pod

=head1 NAME

PLUTO - Son of ODO -> Ontologies, Databases and, Optimization

=head1 SYNOPSIS

 use ODO::Parser::XML;
 use ODO::Graph::Simple;

 print "Parsing RDF/XML file: 'some/path/to/data.rdfxml'\n"n
 my $statements = ODO::Parser::XML->parse_file('some/path/to/data.rdfxml');

 print "Creating in memory graph named: 'http://testuri.org/graphs/#name1'\n";
 my $graph = ODO::Graph::Simple->Memory(name=> 'http://testuri.org/graphs/#name1');

 print "Adding parsed statements to the graph\n";
 $graph->add($statements);

 print 'The graph contains ', $graph->size(), " statements\n";

 # or $graph->add(@{ $statements }); if you are just adding a couple statements
 # and then...

 print "Querying for all statements in the graph\n";
 my $result_set = $graph->query($ODO::Query::Simple::ALL_STATEMENTS);
 my $result_statements = $result_set->results();

 print "Removing statements found in previous query from the graph\n";
 $graph->remove($result_statements);

 print "The graph's size should be 0. Its size is: ", $graph->size(), "\n";

=head1 DESCRIPTION

PLUTO is a repackaged version of ODO. ODO is a framework for processing RDF data.

=head1 CAVEATS

This package contains relatively experimental code and should be treated appropriately.

=head1 AUTHOR

IBM Corporation - ODO creators

Edward Kawas - new ODO (a.k.a PLUTO) maintainer

=head1 SEE ALSO

L<ODO::Statement>, L<ODO::Graph>, L<ODO::Graph::Simple>, L<ODO::Parser>, L<ODO::Parser::XML>, L<ODO::Query::Simple>, L<ODO::Exception>


