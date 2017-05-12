#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Serializer/NTriples.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  04/14/2005
# Revision:	$Id: NTriples.pm,v 1.3 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Serializer::NTriples;

use strict;
use warnings;

use base qw/ODO::Serializer/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ODO::Serializer::NTriples - Serialize statements to NTriples file format

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

Use the L<ODO::Serializer> interface to serialze statements to NTriples format. 
 
=head1 METHODS

=over

=item serialize( \@statements [, $output_file_handle ] )

Serialize the arrayref of L<ODO::Statement> objects to NTriples text. If the
output file handle is left unspecified the serialized text is returned. 

=cut

sub serialize {
	my $self;
	
	$self = shift
		if(scalar(@_) > 2);
	
	my ($statements, $fh) = @_;
	
	my $serialized = "";
	
	foreach my $t (@{ $statements }) {
	
		my $statementString = '';
		
		foreach my $comp ('s', 'p', 'o') {

			if($t->$comp()->isa('ODO::Node::Blank')) {
				$statementString .= $t->$comp()->value() . ' ';
			}		
			elsif($t->$comp()->isa('ODO::Node::Resource')) {
				$statementString .= '<' . $t->$comp()->value() . '> ';
			}
			elsif($t->$comp()->isa('ODO::Node::Literal')) {
				$statementString .= '"' . $t->$comp()->value() . '"';
				
				if($t->$comp()->datatype()) {
					$statementString .= '^^<' . $t->$comp()->datatype() . '>';
				}
				
				if($t->$comp()->language()) {
					$statementString .= '@' . $t->$comp()->language();
				}
				
				$statementString .= ' ';
			}
			else {
				throw ODO::Exception::Runtime(error=> 'Unable to process statement');
			}
		}
		
		if($fh) {
			print $fh $statementString, " .\n";
		}
		else {
			$serialized .= "$statementString .\n";
		}
	}
	
	return $serialized;
}

=back

=head1 COPYRIGHT

Copyright (c) 2005-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
