#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/ObjectWriter/PropertiesContainer.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/28/2006
# Revision:	$Id: PropertiesContainer.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::ObjectWriter::PropertiesContainer;

use strict;
use warnings;

use ODO::Ontology::ObjectWriter::AccessorMethod;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use base qw/ODO::Ontology::ObjectWriter/;

our @METHODS = qw/packageName w ISA properties propertyContainerAccessorFilename/;
our $PROPERTY_CONTAINER_NAME = 'PropertiesContainer';

__PACKAGE__->mk_accessors(@METHODS);

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item serialize( [ %parameters ] )

=cut

sub serialize {
	my $self = shift;

	my $propertiesContainerData = {
		packageName=> $self->packageName(),
		methods=> $self->serializeAccessorMethods(),
		variables=> [],
	};
	
	if($self->ISA()) {
		$propertiesContainerData->{'ISA'} = $self->ISA();
		push @{ $propertiesContainerData->{'variables'} }, '@ISA';
	}
	
	return $self->ODO::Ontology::ObjectWriter::serialize(template_data=> $propertiesContainerData);
}


sub serializeAccessorMethods {
	my $self = shift;
	
	my @accessorMethods;	
	foreach my $p (@{ $self->properties() }) {
		push @accessorMethods, ODO::Ontology::ObjectWriter::AccessorMethod->new(%{ $p }, template_filename=> $self->propertyContainerAccessorFilename())->serialize();
	}
	return \@accessorMethods;
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);

	$self->properties([]);
	
	$self->params($config, @METHODS);
	
	
	# Default tempate filenames	
	$self->template_filename('ODO/Ontology/Templates/PropertyContainer.tt')
		unless(defined($config->{'template_filename'}));
	
	$self->propertyContainerAccessorFilename('ODO/Ontology/Templates/PropertyAccessorMethod.tt')
		unless(defined($config->{'propertyContainerAccessorFilename'}));
	
	return $self;
}


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
