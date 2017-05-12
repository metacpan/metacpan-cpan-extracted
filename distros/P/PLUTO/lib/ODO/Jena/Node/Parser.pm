#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Node/Parser.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/05/2004
# Revision:	$Id: Parser.pm,v 1.2 2009-11-25 17:58:26 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Node::Parser;

use strict;
use warnings;

use base qw/ODO/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /: (\d+)\.(\d+)/;

use ODO::Jena::Node;


=head1 NAME

ODO::Jena::Node::Parser - Package of functions used to parse encoded database statements

=head1 SYNOPSIS

Synopsis

=head1 DESCRIPTION

The functions provided by this package parse statemen strings returned from a database that
was created by Jena L<http://jena.sourceforge.net>.

=head1 METHODS

=over

=item parse( $node_string )

=cut

sub parse {
	my ($self, $node_string) = @_;
	
	foreach my $node_type (qw/literal resource blank variable/) {
		my $fn = "__parse_${node_type}_node";
		my $node = ODO::Jena::Node::Parser->$fn($node_string);
		
		return $node
			if(defined($node));
	}

	# my ( $r_ref_header, $r_long_uri) = ODO::Jena::Node::Parser::isResourceReference($node);
	# my ($br_header, $br_long_uri) = ODO::Jena::Node::Parser::isBlankReference($node);
	
	return undef;
}

=item __parse_literal_node( $string )

Determines whether or not the given string is a Jena literal value.

Parameters:
  $string - The string to examine.

Returns:
 undef if it is not a literal value; an ODO::Jena::Node::Literal otherwise

=cut

sub __parse_literal_node {
	my ($self, $string) = @_;
	
	my $header =
	    ${ODO::Jena::Node::Constants::LITERAL_HEADER}
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER};
	
	return undef
		unless($string =~ /^$header/);
	
	my ($p_header, $lang_len, $datatype_len, $p_value) = ($string =~ /^($header):(\d+):(\d*):(.*):$/);
	
	my $language = '';
	if(defined($lang_len) && $lang_len ne '' && $lang_len > 0) {
		$language = substr($p_value, 0, $lang_len);
	}
	else {
		$lang_len = 0;
	}
	
	my $datatype = '';
	if(defined($datatype_len) && $datatype_len ne '' && $datatype_len > 0) {
		$datatype = substr($p_value, $lang_len, $datatype_len);
	}
	else {
		$datatype_len = 0;
	}
	
	$p_value = substr($p_value,	$lang_len + $datatype_len, length($p_value) - ($lang_len + $datatype_len));
	
	return ODO::Jena::Node::Literal->new(-value=> $p_value, -datatype=> $datatype, -language=> $language);
}


=item __parse_literal_reference( $string)

Determines whether or not the given string is a literal reference.

Parameters:
 $literal - Required. The string to examine.

Returns:
 undef if the string is not a literal reference
=cut

sub __parse_literal_reference {
	my ($self, $string) = @_;

	my $header =
	    $ODO::Jena::Node::Constants::LITERAL_HEADER
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER};

	my ($p_header, $long_id) = $string =~ /^($header):(\d+)/;
	
	return undef
		unless($p_header && $long_id);

	# TODO: Literal reference?
}


=item __parse_resource_node( $string )

Determines whether or not the given string is a resource value.

Parameters:
 $string - The string to examine.

Returns:
 undef if the given string is not a resource value; an ODO::Jena::Node::Resource otherwise

=cut

sub __parse_resource_node {
	my ($self, $string) = @_;
	
	my $header =
	    ${ODO::Jena::Node::Constants::RESOURCE_HEADER}
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER};
	
	return undef
		unless($string =~ /^$header/);
	
	my ($p_header, $prefix_id, $uri, @rest) = split(/:/, $string);
	
	# URLs may have :'s in them which throws the split off
	$uri = join( ':', ($uri, @rest));
	
	return ODO::Jena::Node::Resource->new(-value=> $uri, -prefix_id=> ($prefix_id || '') );
}


=item __parse_resource_reference( $string )

Determines whether or not the given string is a resource reference.

Parameters:
 $resource - Required. The string to examine.

Returns:
 undef if the given string is not a resource reference.

=cut

sub __parse_resource_reference {
	my ($self, $string) = @_;

	my $header =
	    ${ODO::Jena::Node::Constants::RESOURCE_HEADER}
	  . ${ODO::Jena::Node::Constants::REFERENCE_DELIMITER};

	my ($p_header, $long_id) = $string =~ /^($header):(\d+)/;

	return undef
		unless($p_header && $long_id);
	
	# TODO: Return something useful here
}


=item __parse_variable_node( $string )

Determines whether or not the given string is a variable node.

Parameters:
 $string - The string to examine.

Returns:
 undef if it is not a variable node; an ODO::Jena::Node::Variable otherwise

=cut

sub __parse_variable_node {
	my ($self, $string) = @_;
	
	my $header =
	    ${ODO::Jena::Node::Constants::VARIABLE_HEADER}
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER};
	
	return undef
		unless($string =~ /^$header/);
	
	my ($p_header, $p_value) = split(/:/, $string);
	
	return ODO::Jena::Node::Variable->new(-value=> $p_value);
}


=item __parse_blank_node( $string )

Determines whether or not the given string is a blank node.

Parameters:
 $string - The string to examine.

Returns:

 undef if the given string is not a blank node; an ODO::Jena::Node::Blank otherwise

=cut

sub __parse_blank_node  {
	my ($self, $string) = @_;

	my $header =
	    ${ODO::Jena::Node::Constants::BLANK_HEADER}
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER};

	return undef
		unless($string =~ /^$header/);

	my ($p_header, $prefix_id, $blankID, @rest) = split(/:/, $string);

	# There may be :'s in the ID itself which throws the split off
	$blankID = join(':', ($blankID, @rest));
	
	return ODO::Jena::Node::Blank->new(-value=> $string, -prefix_id=> ($prefix_id || ''));
}


=item __parse_blank_reference( $string )

Determines whether or not the given string is a blank node reference.

Parameters:
 $blankID - Required. The string to examine.

Returns:
 undef if the given string is not a blank node reference.

=cut

sub __parse_blank_reference {
	my ($self, $string) = @_;

	my $header =
	    ${ODO::Jena::Node::Constants::BLANK_HEADER}
	  . ${ODO::Jena::Node::Constants::REFERENCE_DELIMITER};

	my ($p_header, $prefix_id, $long_id) = $string =~ /^($header):(\d*):(\d+)/;
	
	return undef
		unless($p_header && $long_id);

	# TODO: Return something useful here
}


=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Jena>, L<ODO::Node>, L<ODO::Jena::Node>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__
