#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/ObjectWriter/Package.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/28/2006
# Revision:	$Id: Package.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::ObjectWriter::Package;

use strict;
use warnings;

use base qw/ODO::Ontology::ObjectWriter/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

our @METHODS = qw/inheritanceMap constructor properties packageName useModules ISA variables varDeclarations baseClasses/;

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

	# Build the Class definition
	my $class_data = {
		packageName=> $self->packageName(),
		useModules=>  $self->useModules(),
		variables=>   $self->variables(),
		ISA=>	      $self->ISA(),
		varDeclarations=> $self->varDeclarations(),
		baseClasses=> $self->baseClasses(),
		constructor=> $self->constructor()->serialize(),
	};

	return $self->ODO::Ontology::ObjectWriter::serialize(template_data=> $class_data, @_);	
}


sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);

	throw ODO::Exception::Parameter::Missing(error=> 'Missing parameter: \'constructor\'')
		unless(defined($config->{'constructor'}));
	
	$self->params($config, @METHODS);
	
	# Borrow the properties from the constructor object 
	# unless they are already present
	unless(defined($config->{'properties'})) {
		$self->properties($self->constructor()->properties());
	}
	
	$self->template_filename('ODO/Ontology/Templates/Package.tt')
		unless(exists($config->{'template_filename'}));

	return $self;
}


1;

__END__
