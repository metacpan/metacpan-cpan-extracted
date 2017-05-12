#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Serializer.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/21/2006
# Revision:	$Id: Serializer.pm,v 1.2 2009-11-25 17:46:51 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Serializer;

use strict;
use warnings;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ODO::Serializer - Base interface for RDF serialization support

=head1 SYNOPSIS
 use ODO::Statement;
 use ODO::Serializer::NTriples;

 my @statements = ( ODO::Statement->new(...), ODO::Statement->new(...) );

 my $serialzed_text = ODO::Serializer::Ntriples->serialize(\@statements);

 # or ...

 ODO::Serializer::NTriples->serialize(\@statements, \*STDOUT);

 # or ... 

 open(OUTFILE, ">output") or die("Unable to open file named 'output' for writing");

 ODO::Serializer::NTriples->serialize(\@statements, \*OUTFILE);

=head1 DESCRIPTION

Base class for statement serializers.

=head1 METHODS

=over

=item serialize( \@statements [, $output_file_handle ] )

Serialize the arrayref of L<ODO::Statement|ODO::Statement> objects to an output format. If the
output file handle is left unspecified the serialized text is returned. 

=cut

use Class::Interfaces('ODO::Serializer'=> 
	{
		'isa'=> 'ODO',
		'methods'=> [ 'serialize' ],
	}
  );

ODO::Serializer->mk_accessors(qw//);

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
