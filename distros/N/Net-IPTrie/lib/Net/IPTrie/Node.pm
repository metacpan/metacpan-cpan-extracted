package Net::IPTrie::Node;

use warnings;
use strict;
use Carp;
use Class::Struct;
use Scalar::Util qw(weaken);
use vars qw($VERSION);
$VERSION = '0.7';

BEGIN {
    struct (
	"Net::IPTrie::_Node" => {
	    'up'        => '$',
	    'left'      => '$',
	    'right'     => '$',
	    'address'   => '$',
	    'iaddress'  => '$',
	    'prefix'    => '$',
	    'data'      => '$',
	});
}

use base qw (Net::IPTrie::_Node);

=head1 NAME

Net::IPTrie::Node

=head1 SYNOPSIS

 See Net::IPTrie

=head1 DESCRIPTION

 See Net::IPTrie

=head1 CLASS METHODS

=head2 new - Constructor

  Arguments:
    up       - Parent node
    left     - Left child node
    right    - Right child node
    address  - Address string
    prefix   - IP prefix (defaults to host mask)
    iaddress - Integer address
    data     - Scalar (could be a reference to any data structure)
  Returns:
    New Net::IPTrie::Node object
  Examples:
    my $n = Net::IPTrie::Node->new(up=>$up, address=>"10.0.0.1")

=cut

sub new {
    my $ret = shift->SUPER::new(@_);
    if ( defined($ret->{'Net::IPTrie::_Node::up'}) ) {
	weaken $ret->{'Net::IPTrie::_Node::up'};
    }
    return $ret;
}

sub up {
    my $self = shift;
    if (@_) {
	$self->{'Net::IPTrie::_Node::up'} = shift;
	if ( defined($self->{'Net::IPTrie::_Node::up'}) ) {
	    weaken $self->{'Net::IPTrie::_Node::up'};
	}
    }
    return $self->{'Net::IPTrie::_Node::up'};
}

=head1 INSTANCE METHODS
=cut

############################################################################

=head2 parent - Find closest parent node with IP information

  Arguments: 
    None
  Returns:   
    Node object with address, or undef
  Examples:  
    my $parent = $node->parent;

=cut

sub parent {
    my ($self) = @_;

    my $p = $self->up;
    while ( defined $p && !defined $p->iaddress ){
	$p = $p->up;
    }
    return $p;
}

############################################################################

=head2 delete - Delete an IP node from the tree

  Note: The node is actually emptied, not deleted

  Arguments: 
    None
  Returns:   
    Deleted (empty) Node object
  Examples:    
   my $n = $tr->find("10.0.0.1");
   $n->delete();

=cut

sub delete {
    my ($self) = @_;
    $self->address(undef);
    $self->iaddress(undef);
    $self->prefix(undef);
    $self->data(undef);
    return $self;
}

# Make sure to return 1
1;

=head1 AUTHOR

Carlos Vicente  <cvicente@cpan.org>

=head1 SEE ALSO

 Net::IPTrie

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2010, Carlos Vicente <cvicente@cpan.org>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
=cut
