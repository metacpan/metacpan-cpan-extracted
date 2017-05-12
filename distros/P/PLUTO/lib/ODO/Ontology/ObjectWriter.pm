#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/ObjectWriter.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  03/02/2005
# Revision:	$Id: ObjectWriter.pm,v 1.3 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::ObjectWriter;

use strict;
use warnings;

use ODO::Exception;

use Template;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_accessors(qw/template_filename/);

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item serialize( template_data=> \%template_data )

=cut

sub serialize {
	my $self = shift;
	my $parameters = $self->params_to_hash(\@_, 0, undef, {});
	
	throw ODO::Exception::Parameter::Missing(error=> 'Missing hashref parameter "template_data"')
		unless(defined($parameters->{'template_data'}));

	throw ODO::Exception::Parameter::Invalid(error=> 'Parameter "template_data" must be a hashref')
		unless(UNIVERSAL::isa($parameters->{'template_data'}, 'HASH'));

	my $tt = Template->new(
			{
				INCLUDE_PATH => join(':', @INC),
				INTERPOLATE  => 0,
			}
		);
		
	throw ODO::Exception::Ontology::Template(error=> $Template::ERROR)
		unless($tt);
	
	my $template_results;
	
	my $process_results = $tt->process($self->template_filename(), $parameters->{'template_data'}, \$template_results);
	throw ODO::Exception::Ontology::TemplateParse(error=> 'Error processing template: ' . $self->template_filename() . ', message: ' . $tt->error())
		unless($process_results);
	
	throw ODO::Exception::Ontology::Template(error=> 'Template results are not defined')
		unless($template_results);

	return $template_results;

}


sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/template_filename/);
	return $self
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
