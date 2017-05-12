#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Ontology/RDFS/BaseClass.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  02/22/2005
# Revision:	$Id: BaseClass.pm,v 1.4 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Ontology::RDFS::BaseClass;

use strict;
use warnings;

use ODO::Exception;

use ODO::Node;

use ODO::Query::Simple;
use ODO::Query::RDQL::Parser;
use ODO::Ontology::RDFS::Vocabulary;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

our @METHODS = qw/graph subject propertyContainerName properties propertyURIMap/;

__PACKAGE__->mk_accessors(@METHODS);

=head1 NAME

ODO::Ontology::RDFS::BaseClass

=head1 SYNOPSIS
	
=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=over

=item value( )

=cut

sub value {
	my $self = shift;
	
	return undef
		unless(UNIVERSAL::isa($self->subject(), 'ODO::Node'));
	
	return $self->subject()->value();
}


=item query( )

=cut

sub query {
	my $self = shift;
	
	my $rdf_map = "rdf for <${ODO::Ontology::RDFS::Vocabulary::RDF}>";
	my $rdfs_map = "rdfs for <${ODO::Ontology::RDFS::Vocabulary::RDFS}>";
	
	my $qs_rdql = 'SELECT ?stmt WHERE ' . $self->queryString() . " USING $rdf_map, $rdfs_map";
			
	my $results = $self->issue_query( $qs_rdql );
	
	my $objects = [];
	while(@{ $results }) {
	
		my $r = shift @{ $results };
		
		my $object = ref $self;
		push @{ $objects }, $object->new($r->subject(), $self->graph());
	}
	
	return (wantarray) ? @{ $objects } : $objects;
}


=item get_property_values( $property_perl_package_name )

=cut

sub get_property_values {
	my ($self, $property_perl_package_name) = @_;
	eval "require $property_perl_package_name";
	# Only Resources can have properties
	throw ODO::Exception::Runtime(error=> 'Subject is not a ODO::Node::Resource')
		unless(UNIVERSAL::isa($self->subject(), 'ODO::Node::Resource'));

	throw ODO::Exception::Runtime(error=> 'Missing graph')
		unless($self->graph());
	
	# Create a triple match that can get all of _THIS_ object's
	# instances of the specific property.
	my $property_query = ODO::Query::Simple->new($self->subject(), ODO::Node::Resource->new($property_perl_package_name->objectURI()), $ODO::Node::ANY);
	
	my $results = $self->graph()->query($property_query)->results();
	
	my $objects = [];
	
	while(@{ $results }) {
		my $r = shift @{ $results };
		push @{ $objects }, $property_perl_package_name->new($r->object(), $self->graph());
	}
	
	return (wantarray) ? @{ $objects } : $objects;
}


=item issue_query( $query )

=cut

sub issue_query {
	my ($self, $query) = @_;
	my $result_set = $self->graph()->query($query);
	my $results = $result_set->results();
	return (wantarray) ? @{ $results } : $results;
}

sub new {
	my ($self, $resource, $graph) = @_;
	return $self->Class::Base::new(subject=> $resource, graph=> $graph);
}

sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/subject graph/);
	$self->propertyURIMap( {} );
	return $self;
}


=back

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
