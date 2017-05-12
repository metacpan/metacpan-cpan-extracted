#
# Copyright (c) 2005-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Jena/Node.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  12/20/2006
# Revision:	$Id: Node.pm,v 1.3 2009-11-25 17:58:25 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Jena::Node;

use strict;
use warnings;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

use Class::Interfaces('ODO::Jena::Node'=> 
	{
		'methods'=> [ 'serialize' ],
	}
  );

=head1 NAME

ODO::Jena::Node - Jena node definitions

=head1 SYNOPSIS

 use ODO::Jena::Node;

=head1 DESCRIPTION

Description.

=head1 COMMON METHODS

=over 

=item reference( )

=item reference( $boolean )

Manipulates whether or not this object is a reference in to the LONG_* tables

Parameters:
 $boolean - Optional. If set, the reference will be set to the given parameter.

Returns:
 Whether or not this object is a reference.

=item is_reference( )

=cut

sub is_reference {
	my $self = shift;	
	return ($self->reference() ? 1 : 0);
}


=item is_value( )

=cut

sub is_value( ) {
	my $self = shift;	
	return (!$self->reference() ? 1 : 0);
}

sub reference {
	my $self = shift;
	defined($_[0]) ? $self->{'reference'} = $_[0] : return $self->{'reference'};
}


sub long_id {
	my $self = shift;
	defined($_[0]) ? $self->{'long_id'} = $_[0] : return $self->{'long_id'}; 
}


=item jena_node( $node )

=cut

sub to_jena_node {
	my ($self, $node) = @_;
	
	return $node
		if(UNIVERSAL::isa($node, 'ODO::Jena::Node'));
	
	my $node_ref = ref $node;
	my ($type) = $node_ref =~ m/::(Literal|Resource|Blank|Variable|Any)$/;
	
	return bless $node, "ODO::Jena::Node::${type}";
}


=back

=head1 NODE TYPES

=cut


package ODO::Jena::Node::Literal;

our @ISA = qw/ODO::Jena::Node ODO::Node::Literal/;

=head2 ODO::Jena::Node::Literal

=over

=item serialize( )

 Literal node encoding:
  Short: Lv:[length(language)]:[length(datatype)]:[language][datatype]value[:]
  Long: Lr:long_id

 Literal node encoding for long literals:
  Lv:[length(language)]:[length(datatype)]:[language][datatype]head[:] hash tail

=cut

sub serialize {
	my $self = shift;

	if($self->is_value()) {
		return    ${ODO::Jena::Node::Constants::LITERAL_HEADER}
				. ${ODO::Jena::Node::Constants::VALUE_DELIMITER}
				. ':' . ($self->language() ? length($self->language()) : '0')
				. ':' . ($self->datatype() ? length($self->datatype()) : '')
				. ':' . $self->value()
				. ':';
	}
	elsif($self->is_reference()) {
		return    ${ODO::Jena::Node::Constants::LITERAL_HEADER}
				. ${ODO::Jena::Node::Constants::REFERENCE_DELIMITER}
				. ':' . $self->long_id();
	}
	else {
		# TODO: Throw an exception
	}
}


sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/reference long_id/);
	return $self->SUPER::init($config);
}

=back

=cut


package ODO::Jena::Node::Resource;

our @ISA = qw/ODO::Jena::Node ODO::Node::Resource/;

use ODO::Node;

__PACKAGE__->mk_ro_accessors(qw/prefix_id/);

=head2 ODO::Jena::Node::Resource

=over

=item serialize( )

 URI node encoding:
  Short: Uv:[prefix_id]:value[:]
  Long: Ur:[prefix_id]:long_id

 URI node encoding for long URIs:
  Uv:head[:] hash tail

=cut

sub serialize {
	my $self = shift;

	if($self->is_value()) {
		return	  ${ODO::Jena::Node::Constants::RESOURCE_HEADER}
				. ${ODO::Jena::Node::Constants::VALUE_DELIMITER}
				. ':' . ($self->prefix_id() || '') . ':'
				. $self->value()
				. ':';
	}
	elsif($self->is_reference()) {
		return    ${ODO::Jena::Node::Constants::RESOURCE_HEADER}
				. ${ODO::Jena::Node::Constants::REFERENCE_DELIMITER}
				. ($self->prefix_id() || '') . ':'
				. $self->long_id();
	}
	else {
		# TODO: Throw an exception
	}
}


sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/prefix_id reference long_id/);
	return $self->SUPER::init($config);
}

=back

=cut


package ODO::Jena::Node::Blank;

our @ISA = qw/ODO::Jena::Node::Resource/;

=head2 ODO::Jena::Node::Blank

=over

=item serialize( )

 Blank node encoding:
  Short: Bv:[prefix_id]:value[:]
  Long: Br:[prefix_id]:long_id

 Blank node encoding for long bnodes:
  Bv:head[:] hash tail

=cut

sub serialize {
	my $self = shift;

	if($self->is_value()) {
		return    ${ODO::Jena::Node::Constants::BLANK_HEADER}
				. ${ODO::Jena::Node::Constants::VALUE_DELIMITER}
				. ($self->prefix_id() || '') . ':'
				. $self->value()
				. ':';
	}
	elsif ( $self->is_reference() ) {
		return    ${ODO::Jena::Node::Constants::BLANK_HEADER}
				. ${ODO::Jena::Node::Constants::REFERENCE_DELIMITER}
				. ($self->prefix_id() || '') . ':'
				. $self->long_id();
	}
	else {
		# TODO: Throw an exception
	}
}


=back

=cut


package ODO::Jena::Node::Variable;

our @ISA = qw/ODO::Jena::Node ODO::Node::Variable/;

=head2 ODO::Jena::Node::Variable

=over

=item serialize( )

Variable node encoding:	'Vv:name'

=cut

sub serialize {
	my $self = shift;
	return
	    ${ODO::Jena::Node::Constants::VARIABLE_HEADER}
	  . ${ODO::Jena::Node::Constants::VALUE_DELIMITER}
	  . $self->name();
}

sub init {
	my ($self, $config) = @_;
	$self->params($config, qw/reference long_id/);
	return $self->SUPER::init($config);
}

=back

=cut


package ODO::Jena::Node::Any;

our @ISA = qw/ODO::Jena::Node ODO::Graph::Node::Any/;

=head2 ODO::Jena::Node::Any

=over

=item serialize( )

Any node encoding: 'Av:'

=cut

sub serialize {
	my $self = shift;	
	return 
		  ${ODO::Jena::Node::Constants::ANY_HEADER}
		. ${ODO::Jena::Node::Constants::VALUE_DELIMITER}
		. ':';
}

=back

=cut


package ODO::Jena::Node::Constants;

our $LITERAL_HEADER = 'L';
our $RESOURCE_HEADER = 'U';
our $VARIABLE_HEADER = 'V';
our $BLANK_HEADER = 'B';
our $ANY_HEADER = 'A';

our $VALUE_DELIMITER = 'v';
our $REFERENCE_DELIMITER = 'r';

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO::Jena>, L<ODO::Node>, L<ODO::Graph>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html

=cut


1;

__END__
