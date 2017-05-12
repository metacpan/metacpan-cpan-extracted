#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: ODO.pm,v 1.7 2010-05-20 17:34:48 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO;

use strict;
use warnings;

our $VERSION = '0.27';

use base qw/Exporter Class::Base Class::Accessor::Fast Class::ParamParser/;

use Time::HiRes qw/gettimeofday tv_interval/;
use Digest::MD5 qw/md5_hex/;

our @EXPORT = qw//;

=pod

=head1 NAME

ODO - Ontologies, Databases and, Optimization

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

ODO is a framework for processing RDF data.

=head1 CAVEATS

This package contains relatively experimental code and should be treated appropriately.

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Statement>, L<ODO::Graph>, L<ODO::Graph::Simple>, L<ODO::Parser>, L<ODO::Parser::XML>, L<ODO::Query::Simple>, L<ODO::Exception>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut

1;

__END__
