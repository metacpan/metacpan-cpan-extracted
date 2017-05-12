package Net::IPTrie;

use warnings;
use strict;
use Carp;
use NetAddr::IP;
use Net::IPTrie::Node;
use vars qw($VERSION);
$VERSION = '0.7';

1;

=head1 NAME

Net::IPTrie - Perl module for building IPv4 and IPv6 address space hierarchies

=head1 SYNOPSIS

    use Net::IPTrie;
    my $tr = Net::IPTrie->new(version=>4);  # IPv4
    my $n  = $tr->add(address=>'10.0.0.0', prefix=>8);
    my $a  = $tr->add(address=>'10.0.0.1', data=>$data) # prefix defaults to 32
    $a->parent->address eq $n->address and print "$a is within $n";

    # Addresses can be provided in integer (decimal) format
    # 10.0.0.7 == 167772167
    my $b = $tr->add(iaddress=>'167772167', data=>'blah');
    if ( my $c = $tr->find(address=>"10.0.0.7" ) {
        print $c->data;  # should print "blah"
    }

   # If the IP does not exist:
   my $d = $tr->find(address=>"10.0.0.8")
   print $d->address;  # should print "10.0.0.0", which is the closest parent block

=head1 DESCRIPTION

 This module uses a radix tree (or trie) to quickly build the hierarchy of a given address space
 (both IPv4 and IPv6).  This allows the user to perform fast subnet or routing lookups.
 It is implemented exclusively in Perl.

=head1 CLASS METHODS

=head2 new - Class Constructor

  Arguments: 
    Hash with the following keys:
    version - IP version (4|6)
  Returns:   
    New Net::IPTrie object
  Examples:    
    my $tr = Net::IPTrie->new(version=>4);

=cut

sub new {
    my ($proto, %argv) = @_;
    croak "Missing required parameters: version" unless defined $argv{version};
    my $class = ref($proto) || $proto;
    my $self = {};
    if ( $argv{version} == 4 ){
	$self->{_size} = 32;
    }elsif ( $argv{version} == 6 ){
	# IPv6 numbers are larger than what a normal integer can hold
	use bigint; 	
	$self->{_size} = 128;
    }else{
	croak("Invalid IP version: $argv{version}");
    }
    $self->{_version} = $argv{version};
    $self->{_trie}    = Net::IPTrie::Node->new();
    bless $self, $class;
    return $self;
}

############################################################################

=head1 INSTANCE METHODS

=head2 version - Set or get IP version (4 or 6)

  Arguments: 
    IP version (4 or 6) - optional
  Returns:   
    version (4 or 6)
  Examples:  
    print $tr->version;

=cut

sub version { 
    my ($self, $v) = @_;
    croak "version is an instance method" unless ref($self);

    $self->{_version} = $v if ( defined $v );
    return $self->{_version};
}

############################################################################

=head2 size - Set or get IP size (32 or 128)

  Arguments:   
    Size (32 or 128) - optional
  Returns:     
    Address size in bits (32 or 128)
  Examples:    
    print $tr->size;   

=cut

sub size { 
    my ($self, $s) = @_;
    croak "size is an instance method" unless ref($self);
    $self->{_size} = $s if ( defined $s );
    return $self->{_size};
}

############################################################################

=head2 find - Find an IP object in the trie

    If the given IP does not exist, there are two options:
    a) If the "deep" flag is off, the closest covering IP block is returned. This is
       the default behavior.
    b) If the "deep" flag is on, the node where the searched IP should be inserted is returned.  
       This is basically only useful for the "add" method.

  Arguments: 
    Hash with following keys:
      address  - String (i.e. "10.0.0.1") address
      iaddress - Integer (i.e. "167772161") address, IPv4 or IPv6.
      prefix   - Prefix Length (optional  - defaults to host mask)
      deep     - Flag (optional). If not found, return the node where object should be inserted.
  Returns:   
    Net::IPTrie::Node object.  
  Examples:    
    my $n = $tr->find("10.0.0.1", 32);

=cut

sub find {
    my ($self, %argv) = @_;
    croak "find is an instance method" unless ref($self);

    my ($address, $iaddress, $prefix, $deep) = @argv{'address', 'iaddress', 'prefix', 'deep'};
    croak "Missing required arguments: address or iaddress" 
	unless (defined $address || defined $iaddress);
    
    $prefix = $self->size unless ( defined $prefix );
    my $p   = $self->{_trie};   # pointer that starts at the root
    my $bit = $self->size;      # Start at the most significant bit

    # Convert string address into integer if necessary
    if ( defined $address && !defined $iaddress ){
	$iaddress = $self->_ip2int($address);
    }

    while ( $bit > $self->size - $prefix ){
	$bit--;

	# bit comparison. 
	my $r = ($iaddress & 2**$bit) == 0 ? 'left' : 'right';
	
	if ( !defined $p->$r ){
	    if ( $deep ){
		# Insert new node
		$p->$r(Net::IPTrie::Node->new(up=>$p));
	    }else{
		# Just return the closest covering IP block
		if ( $p->iaddress ){
		    return $p;
		}else{
		    return $p->parent;
		}
	    }
	}
	
	# Walk one step down the tree
	$p = $p->$r;

	if ( defined $p->iaddress ){
	    # If the address matches, return node
	    if ( $p->iaddress == $iaddress && $p->prefix == $prefix ){
		return $p;
	    }
	}elsif ( !$deep && ($bit == $self->size - $prefix) ){
	    # This is a deleted node
	    return $p->parent;
	}
    }
    # We fell off the bottom.  We tell where to create a new node.
    return $p;
}

############################################################################

=head2 add - Add an IP to the trie

  Arguments: 
    Hash with following keys:
      address  - String address, IPv4 or IPv6 (i.e. "10.0.0.1")  
      iaddress - Integer address, IPv4 or IPv6 (i.e. "167772161") 
      prefix   - Prefix Length (optional - defaults to host mask)
      data     - Data (optional)
  Returns:   
     New Net::IPTrie::Node object
  Examples:    
    my $n = $tr->add(address=>"10.0.0.1", prefix=>32, data=>\$data);

=cut

sub add {
    my ($self, %argv) = @_;
    croak "add is an instance method" unless ref($self);

    my ($address, $iaddress, $prefix, $data) = @argv{'address', 'iaddress', 'prefix', 'data'};
    croak "Missing required arguments: address\n" 
	unless ( defined $address || defined $iaddress );

    $prefix = $self->size unless ( defined $prefix );

    # Convert string address into integer if necessary
    if ( defined $address && !defined $iaddress ){
	$iaddress = $self->_ip2int($address);
    }elsif ( defined $iaddress && !defined $address ){
	$address = $self->_int2ip($iaddress);
    }

    my $n = $self->find(iaddress=>$iaddress, prefix=>$prefix, deep=>1);
    
    unless ( defined $n->iaddress && $n->iaddress == $iaddress ){
	$n->iaddress($iaddress);
	$n->address($address);
	$n->prefix($prefix);
	$n->data($data);
    }
    return $n;
}


############################################################################
=head2 traverse - Traverse every node in the tree

  Arguments: 
    root - node object (optional - defaults to tree root)
    code - coderef (will be passed the Net::IPTrie::Node object to act upon)
    mode - (depth_first only, for now)
  Returns:   
    Number of actual IP nodes visited
  Examples:    
    # Store all IP nodes in an array, ordered.
    my $list = ();
    my $code = sub { push @$list, shift @_ };
    my $count = $tr->traverse(code=>$code);
    
=cut

sub traverse {
    my ($self, %argv) = @_;
    croak "traverse is an instance method" unless ref($self);
    my ($root, $code, $mode) = @argv{'root', 'code', 'mode'};
    
    my $p = $root || $self->{_trie};
    my $count = 0;
    $mode |= 'depth_first';
    if ( $mode eq 'depth_first' ){
	$self->_depth_first(node=>$p, code=>$code, count=>\$count);
    }else{
	croak "Unknown climb mode: $mode";
    }
    return $count;
}


############################################################################
#
# PRIVATE METHODS
#
############################################################################


############################################################################
#  _ip2int - Convert string IP to integer
#
#   Arguments: 
#     IP address in string format ('10.0.0.1')
#   Returns:   
#     IP address in integer format
#   Examples:  
#     my $number = $tr->ip2int('10.0.0.1');
#
sub _ip2int {
    my ($self, $ip) = @_;
    my $nip;
    if ( $self->version == 4 ){
	$nip = NetAddr::IP->new($ip);
    }else{
	$nip = NetAddr::IP->new6($ip);
    }
    croak "Invalid IP: $ip" unless $nip;
    return $nip->numeric;
}

############################################################################
#  _int2ip - Convert integer IP to string
#
#   Arguments: 
#     IP address in integer format
#   Returns:   
#     IP address in string format
#   Examples:  
#     my $dottedquad = $tr->_int2ip(167772161);
#
sub _int2ip {
    my ($self, $int) = @_;
    my $nip;
    if ( $self->version == 4 ){
	$nip = NetAddr::IP->new($int);
    }else{
	$nip = NetAddr::IP->new6($int);
    }
    croak "Invalid IP integer: $int" unless $nip;
    return $nip->addr;
}

############################################################################
# _depth_first - Recursively visit each node in depth-first mode
#
#  Arguments: 
#  Hash with following key/value pairs:
#     node  - Starting node
#     code  - coderef (will be passed the Net::IPTrie::Node object to act upon)
#     count - Scalar reference
#  Returns:   
#  Examples:    
#
#
sub _depth_first {
    my ($self, %argv) = @_;
    my ($n, $code, $count) = @argv{'node', 'code', 'count'};
    
    if ( $n->address ){
	if ( defined $code && ref($code) eq "CODE" ){
	    # execute code
	    $code->($n);
	}
	$$count++;
    }
    $self->_depth_first(node=>$n->left,  code=>$code, count=>$count) if ( defined $n->left  );
    $self->_depth_first(node=>$n->right, code=>$code, count=>$count) if ( defined $n->right );
}

=head1 AUTHOR

Carlos Vicente  <cvicente@cpan.org>

=head1 SEE ALSO

Net::IPTrie::Node
Net::Patricia 

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
