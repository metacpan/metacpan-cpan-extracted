#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/ObjectWriter.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  05/04/2005
# Revision:	$Id: ObjectWriter.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Lite::ObjectWriter;

package ODO::Ontology::OWL::Lite::ObjectWriter::Package;

use base qw/ODO::Ontology::ObjectWriter::Package/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

package ODO::Ontology::OWL::Lite::ObjectWriter::PropertyInitializer;

use base qw/ODO::Ontology::ObjectWriter/;

our @METHODS = qw/shortName packageName/;

__PACKAGE__->mk_accessors(@METHODS);


=item serialize( )

=cut

sub serialize {
	my $self = shift;
	
	my $property_initializer = {
		shortName=> $self->shortName(),
		packageName=> $self->packageName(),
	};
	
	return $self->SUPER::serialize(template_data=> $property_initializer);
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	$self->template_filename('ODO/Ontology/OWL/Lite/Templates/OWLLitePropertyInitializer.tt');
	return $self;
}

package ODO::Ontology::OWL::Lite::ObjectWriter::PropertyContainer;

use base qw/ODO::Ontology::ObjectWriter::PropertiesContainer/;


package ODO::Ontology::OWL::Lite::ObjectWriter::AccessorMethod;

use base qw/ODO::Ontology::ObjectWriter::AccessorMethod/;

sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	$self->template_filename('ODO/Ontology/OWL/Lite/Templates/OWLLitePropertyAccessorMethod.tt');
	return $self;
}

package ODO::Ontology::OWL::Lite::ObjectWriter::Constructor;

use strict;
use warnings;

use ODO::Exception;

use base qw/ODO::Ontology::ObjectWriter/;

our @METHODS = qw/URI description schemaURI propertyContainerName properties queryString queryObject cardinalityRestrictions classIntersections restrictedIntersections/;
__PACKAGE__->mk_accessors(@METHODS);


sub serializePropertyInitializers {
	my $self = shift;
	
	my @initializerMethods;		
	foreach my $p (@{ $self->properties() }) {
		push @initializerMethods, ODO::Ontology::OWL::Lite::ObjectWriter::PropertyInitializer->new(%{ $p })->serialize();
	}
	return \@initializerMethods;
}

=item serialize( )

=cut

sub serialize {
	my $self = shift;
	
	my $cons_data = {
		URI=> $self->URI(),
		description=> $self->description(),
		schemaURI=> $self->schemaURI(),
		queryString=> $self->queryString(),
		propertyInitializers=> $self->properties(),
		propertyContainerName=> $self->propertyContainerName(),
		properties=> $self->properties(),
		cardinalityRestrictions=> $self->cardinalityRestrictions(),
		classIntersections=> $self->classIntersections(),
	};
	
	return $self->SUPER::serialize(template_data=> $cons_data);
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	$self->params($config, @METHODS);
	$self->template_filename('ODO/Ontology/OWL/Lite/Templates/OWLLiteConstructor.tt');
	return $self;
}

1;

__END__

