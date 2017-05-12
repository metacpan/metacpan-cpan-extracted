#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Parser.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  10/05/2004
# Revision:	$Id: Parser.pm,v 1.7 2009-11-25 17:46:52 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Parser;

use strict;
use warnings;

use ODO::Exception;
use ODO::Node;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

use XML::Namespace
	rdf=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';

use base qw/ODO/;

our @__EXPORTED_RDF_NODES = qw/$REIFY_SUBJECT $REIFY_PREDICATE $REIFY_OBJECT $REIFY_STATEMENT $RDF_TYPE $RDF_NIL $RDF_FIRST $RDF_REST $RDF_LIST/;
our @EXPORT_OK = @__EXPORTED_RDF_NODES;
our %EXPORT_TAGS = (RDF_NODES => [ @__EXPORTED_RDF_NODES ] );

=pod

=head1 NAME

ODO::Parser - Generic parser interface for ODO RDF Parsers

=head1 SYNOPSIS
 use ODO::Parser::XML;

 my $statements = ODO::Parser::XML->parse_file('some/path/to/data.rdfxml');

 my $rdf = ' ... rdf xml here ... ';
 my $other_statements = ODO::Parser::XML->parse(\$rdf);

=head1 DESCRIPTION

This specifies the base interface for parsing RDF in ODO. RDF parsers must support the two
functions defined here: parse and parse_file.

=head1 METHODS

=over

=item parse( $rdf_text | \$rdf_text )

Parse RDF from the scalar or scalarref parameter. An arrayref of L<ODO::Statement> objects
will be returned.  

=item parse_file( $filename )

Parse RDF from the file parameter. An arrayref of L<ODO::Statement> objects
will be returned.  

=cut

use Class::Interfaces('ODO::Parser'=> 
	{
		'isa'=> 'ODO',
		'methods'=> [ 'parse', 'parse_file' ],
	}
  );

__PACKAGE__->mk_accessors(qw//);

our $REIFY_SUBJECT = ODO::Node::Resource->new(rdf->uri('subject'));
our $REIFY_PREDICATE = ODO::Node::Resource->new(rdf->uri('predicate'));
our $REIFY_OBJECT = ODO::Node::Resource->new(rdf->uri('object'));
our $REIFY_STATEMENT = ODO::Node::Resource->new(rdf->uri('statement'));
our $RDF_TYPE = ODO::Node::Resource->new(rdf->uri('type'));
our $RDF_NIL = ODO::Node::Resource->new(rdf->uri('nil'));
our $RDF_FIRST = ODO::Node::Resource->new(rdf->uri('first'));
our $RDF_REST = ODO::Node::Resource->new(rdf->uri('rest'));
our $RDF_LIST = ODO::Node::Resource->new(rdf->uri('List'));

=back

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
