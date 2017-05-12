#
#  Licensed Materials - Property of IBM
#  
#  (C) Copyright IBM Corporation 2006  All Rights Reserved.
#  
#  $Id: RDFAttributes.pm,v 1.10 2009-11-25 17:54:26 ubuntu Exp $
#

package ODO::Parser::XML::RDF::Attributes;

use strict;
use warnings;

use base qw/ODO/;
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.10 $ =~ /: (\d+)\.(\d+)/;
use ODO::Exception;

use XML::Namespace
	rdf=> 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
;

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 RDF ATTRIBUTES

=over

=item Attributes requiring a RDF URI prefix

=cut

our $REQUIRED_PREFIX = {
   'about'=> 1,
   'ID'=> 1,
   'type'=> 1,
   'resource'=> 1,
   'parseType'=> 1,
};

=item Prohibited attributes

=cut

our $PROHIBITED_ATTRIBUTES = {
	'li'=> 1,
};


=item Withdrawn attributes 

=cut

our $WITHDRAWN_ATTRIBUTES = {
   'bagID'=> 1,
   'aboutEach'=> 1,
   'aboutEachPrefix'=> 1,
};

=back

=head1 METHODS

=over 

=item is_withdrawn( $attribute )

=cut

sub is_withdrawn {
	shift;
	return 	exists($WITHDRAWN_ATTRIBUTES->{ $_[0] });	
}


=item needs_namespace( $attribute )

=cut

sub needs_namespace {
	shift;
	return 	exists($REQUIRED_PREFIX->{ $_[0] });
}


=item is_prohibited( $attribute )

=cut

sub is_prohibited {
	shift;

	return 1
		if($_[0] eq rdf->uri() && 
			exists($PROHIBITED_ATTRIBUTES->{ $_[1] }));

	return 0;
}

=item to_string( )

=cut

sub to_string {
	shift;
	
	my $attributes = shift;
	
	my $string = '';
	
	while ( my ( $k, $v ) = each(%{ $attributes }) ) {
		$string .= "$k=\"$v\" ";
	}
	
	return $string;
}

sub init {
	my ($self, $config) = @_;
	
	my $attributes = {};

	while ( my ( $k, $v ) = each(%{ $config }) ) {

		throw XML::SAX::Exception::Parse(Message=> 'RDF attribute "' . $v->{'LocalName'} . '" has been withdrawn.')
			if($self->is_withdrawn( $v->{'LocalName'} ));
		
		throw XML::SAX::Exception::Parse(Message=> 'RDF attribute "' . $v->{'LocalName'} . '" must have rdf: prefix.')
			if($self->needs_namespace( $v->{'LocalName'}) && !$v->{'NamespaceURI'});

		throw XML::SAX::Exception::Parse(Message=> 'RDF attribute "' . $v->{'LocalName'} . '" is prohibited from attributes.')
			if($self->is_prohibited( $v->{'NamespaceURI'}, $v->{'LocalName'}));
		
		# Make sure our LocalName and NamespaceURI have the proper separator
		$v->{'NamespaceURI'} .= '#'
			if(! ($v->{'NamespaceURI'} =~ m|/$| || $v->{'NamespaceURI'} =~ m|#$|) );
		
		$attributes->{ $v->{'NamespaceURI'} . $v->{'LocalName'} } = $v->{'Value'};
	}
	
	

	return $attributes;
}

=head1 COPYRIGHT

Copyright (c) 2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut

1;

__END__
