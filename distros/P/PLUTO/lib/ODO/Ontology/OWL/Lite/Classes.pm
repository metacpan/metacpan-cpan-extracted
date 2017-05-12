#
# Copyright (c) 2005-2007 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/OWL/Lite/Classes.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  05/11/2005
# Revision:	$Id: Classes.pm,v 1.26 2010-03-09 17:57:59 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::OWL::Lite::Classes;

use strict;
use warnings;

use ODO::Node;
use ODO::Exception;
use ODO::Query::Simple;
use ODO::Ontology::RDFS::Vocabulary;

use ODO::Ontology::OWL::Lite::Fragments;
use ODO::Ontology::OWL::Lite::Restriction;
use ODO::Ontology::OWL::Lite::Properties;
use ODO::Ontology::OWL::Vocabulary;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.27 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_accessors(qw/graph/);
__PACKAGE__->mk_ro_accessors(qw/classes fragments/);


sub init {
	my ($self, $config) = @_;

	$self->params($config, qw/graph/);

	$self->{'classes'} = {};
	$self->{'fragments'} = ODO::Ontology::OWL::Lite::Fragments->new(graph=> $self->graph());
	
	$self->__make_class_objects();
	
	return $self;
}


sub __make_class_objects {
	my $self = shift;
	
	my $rawClasses = $self->fragments()->getClasses();
	
	throw ODO::Exception::Runtime(error=> 'Could not get class fragment interface ODO::Ontology::OWL::Lite::Fragments::Classes')
		unless($rawClasses->isa('ODO::Ontology::OWL::Lite::Fragments::Classes'));
	
	
	#
	# It's much easier to define each one of these classes so that 
	# when we process the subClassOf properties we know if the class
	# is a named class or a blank class that should be used in a 
	# restriction
	#
	foreach my $rawClass (@{ $rawClasses }) {
		$self->classes()->{ $rawClass->subject()->value() } = { object=> $rawClass->subject() };
	}
	
	foreach my $rawClass (@{ $rawClasses }) {
		$self->__fill_class($self->classes()->{ $rawClass->subject()->value() });
	} 
}


sub __fill_class {
	my ($self, $class) = @_;
	
	my $classURI = $class->{'object'}->value();
	
	$class->{'intersections'} = $self->fragments()->getClassIntersectionOf($classURI);
	$class->{'unions'} = $self->fragments()->getClassUnionOf($classURI);
		
    my @inheritance;
    my @restrictions;
    my @equivalentclasses;
    
    my $subClassOf = $self->__get_schema_data($classURI, $ODO::Ontology::RDFS::Vocabulary::subClassOf);
    foreach my $sc (@{ $subClassOf }) {
        # Only accept sub classes if we have defined the class,
        # everything else is a restriction.
        if(exists($self->classes()->{ $sc })) {
            push @inheritance, $sc
        }
        else {
            # This is a restriction class
            my $r = $self->fragments()->getClassRestriction($sc);
            # this could be a subclass uri (perhaps the model doesnt include a definition)
            push @restrictions, $r if scalar(keys(%{$r})) > 1;
            unless (scalar(keys(%{$r})) > 1) {
                push @inheritance, $sc;
                warn("please make sure to import or define: $sc");
            }
        }
    }
    
    #process equivalent class
    $subClassOf = $self->__get_schema_data($classURI, $ODO::Ontology::OWL::Vocabulary::equivalentClass);
    foreach my $sc (@{ $subClassOf }) {
        # $sc is a nodeURI
        
        # Only accept equivalent classes if we have defined the class,
        # everything else is a restriction.
        if(exists($self->classes()->{ $sc })) {
            push @equivalentclasses, $sc;
        }
        else {
            # This is a restriction class
            my $r = $self->fragments()->getEquivalentClasses($sc, $classURI );
            push @equivalentclasses, $r;
        }
    }
    
    $class->{'equivalent'} = \@equivalentclasses;
    $class->{'inheritance'} = \@inheritance;
    $class->{'restrictions'} = \@restrictions;
}


# TODO: Fix this so that it is documented better and factored out
# __get_schema_data( $schemaObject, $property )
#
sub __get_schema_data {
	my ($self, $schemaObject, $property) = @_;
	
	$schemaObject = ODO::Node::Resource->new( $schemaObject )
		unless($schemaObject->isa('ODO::Node::Resource'));
		
	$property = ODO::Node::Resource->new( $property )
		unless($property->isa('ODO::Node::Resource'));
	
	my $query = ODO::Query::Simple->new($schemaObject, $property, undef);
	
	my @results = map { $_->o()->value() } @{ $self->graph()->query($query)->results() };
	
	return \@results;
}

1;

__END__
