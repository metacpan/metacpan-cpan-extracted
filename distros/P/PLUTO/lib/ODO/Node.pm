#
# Copyright (c) 2004-2006 IBM Corporation.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
# 
# File:        $Source: /var/lib/cvs/ODO/lib/ODO/Node.pm,v $
# Created by:  Stephen Evanchik( <a href="mailto:evanchik@us.ibm.com">evanchik@us.ibm.com </a>)
# Created on:  11/02/2004
# Revision:	$Id: Node.pm,v 1.4 2010-02-17 17:20:23 ubuntu Exp $
# 
# Contributors:
#     IBM Corporation - initial API and implementation
#
package ODO::Node;

use strict;
use warnings;

use base qw/ODO/;

use Digest::MD5 qw/md5_hex/;

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

__PACKAGE__->mk_accessors(qw/value/);

=head1 NAME

ODO::Node

=head1 SYNOPSIS

 use ODO::Node;

 # Classes within this package:
 #
 #  ODO::Node
 #  ODO::Node::Literal
 #  ODO::Node::Resource
 #  ODO::Node::Blank
 #  ODO::Node::Variable
 #  ODO::Node::Any

=head1 DESCRIPTION

Description.

=head1 CONSTRUCTOR

Constructor.

=cut

sub new {
	my $self = shift;
	my ($node) = @_;

	return $node
		if(    scalar(@_) == 1
		    && $node->isa( ref $self )
		 );
			#&& UNIVERSAL::isa($node, $self));
	
	return $self->SUPER::new(@_);
}

=head1 ODO::Node

=head2 DESCRIPTION

The base class for all node types.

=head2 METHODS

=over

=item value( [ $value ] )

Manipulates the actual value of the object (resource or literal).

Parameters:
 $value - Optional. If set, the value will be set to the given parameter.

Returns:
 The value stored by this object.

=item equal( $node )

Determines whether the node is the same as the node passed
to this function

=cut

sub equal {
	my ($self, $this_node) = @_;

	return 1 
		if(   $this_node->isa('ODO::Node::Any') # UNIVERSAL::isa($this_node, 'ODO::Node::Any') 
		   || $self->isa('ODO::Node::Any') # UNIVERSAL::isa($self, 'ODO::Node::Any')
		);
	
	return ($this_node->hash() eq $self->hash()) ? 1 : 0;
}

=item hash( )

=cut

sub hash {
	my $self = shift;

	if(!defined($self->{'_hash_value'})) {
		$self->{'_hash_value'} = md5_hex($self->value());
	}
		
	return $self->{'_hash_value'};	 
}


sub init {
	my ($self, $config) = @_;
	
	return $config->{'value'}
		if(UNIVERSAL::isa($config->{'value'}, ref $self));
		
	$self->params($config, qw/value/);
	return $self;
}


=back

=cut


package ODO::Node::Literal;

use strict;
use warnings;

our @ISA = ('ODO::Node');

__PACKAGE__->mk_accessors(qw/language datatype/);

=head1 ODO::Node::Literal

=head2 DESCRIPTION

Literal node type.

=head2 METHODS

=over

=item new( $value, $language, $datatype )

Create a new literal node with the specified value and optional language and datatype.

=cut

sub new {
	my $self = shift;
	my $params = $self->params_to_hash(\@_, 1, [qw/value language datatype/], { 'literal'=> 'value' } );
	return $self->SUPER::new(%{ $params });	
}


=item language( [ $language ] )

Get or set the language element of the node.

=item datatype( [ $datatype ] )

Get or set the datatype element of the node.

=cut

sub init {
	my ($self, $config) = @_;
	$self = $self->SUPER::init($config);
	$self->params($config, qw/language datatype/);
	return $self;
}


=back

=cut

package ODO::Node::Resource;

use strict;
use warnings;

our @ISA = ('ODO::Node');

=head1 ODO::Node::Resource

=head2 DESCRIPTION

The URI / resource node type.

=head2 METHODS

=over

=item new( $uri_value )

=cut

sub new {
	my $self = shift;
	my $params = $self->params_to_hash(\@_, 1, [qw/value/], { 'uri' => 'value' } );
	return $self->SUPER::new(%{ $params });
}

=item uri()

Alias for OOD::Node::value

=cut

no strict;
no warnings;

*uri = \&ODO::Node::value;

use strict;
use warnings;


=back

=cut


package ODO::Node::Blank;

use strict;
use warnings;

our @ISA = ('ODO::Node::Resource');

=head1 ODO::Node::Blank

=head2 DESCRIPTION

The blank node type.

=head2 METHODS

=over

=item new( [ $value ] )

Create a new blank node with the specified value.

=cut

sub new {
	my $self = shift;
	my $params = $self->params_to_hash(\@_, 1, [qw/value/], { 'node_id' => 'value' } );
	return $self->Class::Base::new(%{ $params });
}

=item node_id( [ $value ] )

Alias for SUPER::value

=cut

no strict;
no warnings;

*node_id = \&ODO::Node::value;

use strict;
use warnings;

=back

=cut

package ODO::Node::Variable;

use strict;
use warnings;

our @ISA = ('ODO::Node');

=head1 ODO::Node::Variable

=head2 DESCRIPTION

The variable node type.

=head2 METHODS

=over

=item new( $name_val | name=> $name_val )

=cut

sub new {
	my $self = shift;
	my $params = $self->params_to_hash(\@_, 1, [qw/value/], { 'name' => 'value' } );
	return $self->SUPER::new(%{ $params });
}

=item name()

Alias for SUPER::value

=cut

no strict;
no warnings;

*name = \&ODO::Node::value;

use strict;
use warnings;


=back

=cut

package ODO::Node::Any;

use strict;
use warnings;

our @ISA = ('ODO::Node');

=head1 ODO::Node::Any

=head2 DESCRIPTION

The node that matches any node.

=head2 METHODS

=over

=item value()

ANY nodes don't have a value

=cut

sub value {
	return undef;
}

=item equal( $node )

The ANY node type is equal to everything 

=cut

sub equal {
	return 1;
}

=item $ODO::Node::ANY

=cut

no warnings;

$ODO::Node::ANY = ODO::Node::Any->new();

use warnings;


=back

=cut

package ODO::Node::Constants;

use strict;
use warnings;

=head1 ODO::Node::Constants

=head2 DESCRIPTION

Constants that can be used by the node subsystem.

=head2 CONSTANTS

=head3 URI Regular Expression

=over

=item Official URI regular expression

$URI =~ ^(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?

=cut

our $URI_REGEXP = '^(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?';

=back

=head1 AUTHOR

IBM Corporation

=head1 SEE ALSO

L<ODO>, L<ODO::Statement>

=head1 COPYRIGHT

Copyright (c) 2004-2006 IBM Corporation.

All rights reserved. This program and the accompanying materials
are made available under the terms of the Eclipse Public License v1.0
which accompanies this distribution, and is available at
http://www.eclipse.org/legal/epl-v10.html


=cut


1;

__END__
