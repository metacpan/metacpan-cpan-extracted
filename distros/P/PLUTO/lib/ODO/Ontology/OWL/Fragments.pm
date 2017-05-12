#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Fragments.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  03/02/2005
# Revision:	$Id: Fragments.pm,v 1.4 2010-02-17 17:17:09 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Fragments;

use strict;
use warnings;

use ODO::Exception;

use ODO::Ontology::OWL::Vocabulary;
use ODO::Ontology::RDFS::Vocabulary;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

ODO::Ontology::OWL::Fragments

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 AUTOLOAD

=head1 METHODS

=over

=item getClassOneOf( $class, $classURI )

=cut

sub getClassOneOf {
	my ($self, $class, $classURI) = @_;

	$classURI = $class->value()
		if($class->isa('ODO::Node::Resource'));
		
	my $owlOneOf = $ODO::Ontology::OWL::Vocabulary::oneOf;
	
	# Find the owl:Class objects first
	my $queryString = "SELECT ?stmt WHERE (<$classURI>, <$owlOneOf>, ?list)";
	
	my $results = $self->graph()->query( $queryString )->results();

	# Note: not a blessed reference
	return (wantarray) ? @{ $results } : $results;
}


=item getClassUnionOf( $class, $classURI )

=cut

sub getClassUnionOf {
	my ($self, $class, $classURI) = @_;

	$classURI = $class->value()
		if($class->isa('ODO::Node::Resource'));
		
	my $owlUnionOf = $ODO::Ontology::OWL::Vocabulary::unionOf;
	
	# Find the owl:Class objects first
	my $queryString = "SELECT ?stmt WHERE (<$classURI>, <$owlUnionOf>, ?list)";
	
	my $results = $self->graph()->query( $queryString )->results();

	my $list = ODO::RDFS::List->new($results->[0]->object(), $self->graph());
	my $listIter = ODO::Ontology::RDFS::List::Iterator->new($list);
	unless($listIter->isa('ODO::Ontology::RDFS::List::Iterator')) {
		die("Could not create iterator for ODO::RDFS::List");
	}

	# Iterate through the list keeping the string value in the results
	# returned to the caller
	$results = [];
	
	my $iterElement;
	while( ($iterElement = $listIter->next()) ) {

		if($iterElement->isa('ODO::Node::Blank')) {
			# TODO: Die here?
		}
		else {
			push @{ $results }, $iterElement->value();
		}
	}

	# Note: not a blessed reference
	return (wantarray) ? @{ $results } : $results;
}


=item getClassComplementOf( $class, $classURI )

=cut

sub getClassComplementOf {
	my ($self, $class, $classURI) = @_;

	$classURI = $class->value()
		if($class->isa('ODO::Node::Resource'));
		
	my $owlComplementOf = $ODO::Ontology::OWL::Vocabulary::complementOf;
	
	# Find the owl:Class objects first
	my $queryString = "SELECT ?stmt WHERE (<$classURI>, <$owlComplementOf>, ?list)";
	
	my $results = $self->graph()->query( $queryString )->results();

	# Note: not a blessed reference
	return (wantarray) ? @{ $results } : $results;
}


=item getDatatypeRange( )

=cut

sub getDatatypeRange {
	my ($self, $rangeURI) = @_;

	my $owlDataRange = $ODO::Ontology::OWL::Vocabulary::DataRange;
	
	my $queryString = "SELECT ?stmt WHERE (<$rangeURI>, <$owlDataRange>, ?list)";
	
	my $results = $self->graph()->query( $queryString )->results();

	my $list = ODO::RDFS::List->new($results->[0]->object(), $self->graph());
	my $listIter = ODO::Ontology::RDFS::List::Iterator->new($list);

	throw ODO::Exception::Runtime(error=> "Could not create iterator for ODO::RDFS::List")
		unless($listIter->isa('ODO::Ontology::RDFS::List::Iterator'));

	$results = [];
	
	my $iterElement;
	while( ($iterElement = $listIter->next()) ) {
		push @{ $results }, $iterElement->value();
	}
	
	return (wantarray) ? @{ $results } : $results;
}


=item getPropertyRange( )

=cut

sub getPropertyRange {
	my ($self, $propertyURI) = @_;

	my $results = $self->SUPER::getPropertyRange($propertyURI);
	
	if(scalar(@{ $results }) == 1 && $results->[0]->object()->isa('ODO::Node::Blank')) {
		$results = $self->getDatatypeRange($results->[0]->object()->value());
	}

	return (wantarray) ? @{ $results } : $results;
}


=item getPropertyDomain( )

=cut

sub getPropertyDomain {
	my ($self, $propertyURI) = @_;

	my $owlUnionOf = $ODO::Ontology::OWL::Vocabulary::unionOf;
	
	my $results = $self->SUPER::getPropertyDomain($propertyURI);
	
	# If this domain is a union .. break them out
	if(scalar(@{ $results }) == 1) {
	
		my $unionClassURI = $results->[0]->object()->value();
		my $unionResults = $self->getClassUnionOf($unionClassURI);
		
		return (wantarray) ? @{ $results } : $results
			unless(scalar(@{ $unionResults }) > 0);
			
		$results = $unionResults;
	}
	
	return (wantarray) ? @{ $results } : $results;
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