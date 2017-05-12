#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Query/Simple/Mapper.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  01/17/2005
# Revision:	$Id: Mapper.pm,v 1.2 2009-11-25 17:53:53 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Query::Simple::Mapper;

use strict;
use warnings;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;
use ODO::Node;
use ODO::Statement;

use base qw/ODO/;

__PACKAGE__->mk_accessors(qw/mapping/);

=head1 NAME

ODO::Query::Simple::Mapper

=head1 SYNOPSIS

Synopsis.

=head1 DESCRIPTION

Description.

=head1 METHODS

=over

=item new( $source_simple_query, $dest_simple_query )

This object creates a mapping between the variables of two ODO::Query::Simple
objects's. For example, if T1 contains the variable named 'A' in its subject 
and T2 contains the variable 'A' in its object then the new 
ODO::Query::Simple::Mapper object will return 'object' when its subject 
method is invoked, i.e:

		($mapper->subject() eq 'object' == 1)

This can be used to compare statements with respect to their variables.

=cut


sub new {
	my ($self, $source, $dest) = @_;
	return $self->SUPER::new(source=> $source, dest=> $dest);
}


=item compare( $source, $dest )

compare does the following:

	1. Determine if the (s, p, o) of the source statement maps on to 
	   either the s, p, or o of the destination statement.
	2. If it does, compare the source statement's component to the
	   destination statement's component.
	3. If they do not match return false
	4. Return true if we make it through the loop

=cut

sub compare {
	my ($self, $source, $dest) = @_;
	
	foreach my $component ('s', 'p', 'o') {
	
		my $destComponent = $self->$component();
		
		next
			unless($destComponent);
		
		# The component's variable matches now see if the value
		# matches
		return 0
			unless($source->$component()->equal($dest->$destComponent()));
	}
	
	return 1;	
}


=item find_var( $statementMatch, $variableNode )

Looks for a variable in one of the components of the destination
statement.

=cut

sub find_var {
	my ($self, $tm, $var) = @_;
			
	foreach my $c ( 's', 'p', 'o') {

		return $c
			if($tm->$c()->value() eq $var->value());
	}
	
	return undef;
}


sub BEGIN {

	no strict 'refs';
	
	foreach my $comp ('s', 'p', 'o') {
	
		my $fn = __PACKAGE__ . "::$comp";
		
		*$fn = sub {
			my $self = shift;
			
			# A mapping may not exists for this particular statement match
			# component
			return undef
				unless(exists($self->mapping()->{ $comp }));

			return $self->mapping()->{ $comp };			
		};
	}
	
	use strict;
}


no warnings;

*subject = \&s;
*predicate = \&p;
*object = \&o;

use warnings;


sub init {
	my ($self, $config) = @_;
	
	my $source = $config->{'source'};
	my $dest = $config->{'dest'};

	$self->mapping( {} );
	
	foreach my $component ('s', 'p', 'o') {
	
		next
			unless(UNIVERSAL::isa($source->$component(), 'ODO::Node::Variable'));
		
		my $mapped_component = $self->find_var($dest, $source->$component());
		
		next
			unless($mapped_component);
					
		# At this point make it so that $self->subject() points to 
		# $dest->(subject|predicate|object)
		$self->mapping()->{ $component } = $mapped_component;
	}		
	
	return $self;
}


=back

=head1 AUTHOR

IBM Corporation

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
