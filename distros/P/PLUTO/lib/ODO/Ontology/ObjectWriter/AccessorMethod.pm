#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/ObjectWriter/AccessorMethod.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/28/2006
# Revision:	$Id: AccessorMethod.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::ObjectWriter::AccessorMethod;

use strict;
use warnings;

use base qw/ODO::Ontology::ObjectWriter/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

our @METHODS = qw/shortName packageName/;

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
	
	my $accessor_method_data = {
		shortName=> $self->shortName(),
		packageName=> $self->packageName(),
	};
	
	return $self->ODO::Ontology::ObjectWriter::serialize(template_data=> $accessor_method_data);	
}


sub init {
	my ($self, $config) = @_;
	$self->SUPER::init($config);
	$self->params($config, @METHODS);
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
