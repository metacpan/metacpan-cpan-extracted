#
# Copyright (c) 2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Constraint.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/02/2004
# Revision:	$Id: Constraint.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Constraint;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
__PACKAGE__->mk_accessors(qw/operation is_unary left right/);

=head1 NAME

ODO::Query::Constraint - A Constraint on a statement Query

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over

=item new( )

=item left( )

=item right( )

=item is_unary( )

=item is_terminal( )

=cut

sub is_terminal {
	my $self = shift;
	
	if(   !UNIVERSAL::isa($self->left(), 'ODO::Query::Constraint')
	   && !UNIVERSAL::isa($self->right(), 'ODO::Query::Constraint')) {
	
		return 1;   
	}
	
	return 0;
}

=item print( )

=cut

sub print {
	my ($self, $fh) = @_;
	
	$fh = \*STDERR
		unless($fh);
	
	if($self->is_unary() ) {
		print $fh $self->operation(), ' ';
	}
	
	if($self->is_terminal()) {
		print $fh $self->left()->value(), ' ';
		print $fh $self->operation(), ' ', $self->right()->value(), ' '
			if($self->right());
	}
	else {
		my $lC = $self->left();
		my $rC = $self->right();
		
		if(UNIVERSAL::isa($lC, 'ODO::Query::Constraint')) {
			$lC->print($fh);
		}
		elsif(UNIVERSAL::isa($lC, 'ODO::Node')) {
			print $fh $lC->value(), ' ';			
		}		
	
		if(UNIVERSAL::isa($rC, 'ODO::Query::Constraint')) {
			print $fh $self->operation(), ' ';
	
			print $fh ' ( ';
			$rC->print($fh);
			print $fh ' ) ';
		}
		elsif(UNIVERSAL::isa($rC, 'ODO::Node')) {
			print $fh $self->operation(), ' ', $rC->value(), ' ';
		}
			
	}
}

sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/left right is_unary operation/);
	return $self;
}

=back

=head1 AUTHOR

IBM Corporation

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
