=head1 NAME

Net::CIDR::Lookup::IPv6

=head1 DESCRIPTION

This is the IPv6 version of L<Net::CIDR::Lookup|Net::CIDR::Lookup>. It generally provides the
same methods, with the distinction that the C<add_num>/C<add_num_range> methods
that accept an IPv4 address as an integer have been split in two to accommodate
different representations for an IPv6 address:

=over 1

=item C<add_vec>/C<add_vec_range> accepts a 128-bit L<Bit::Vector|Bit::Vector> object for an address

=item C<add_str>/C<add_str_range> takes a packed string as returned by C<Socket::unpack_sockaddr_in6>

=back

For all other methods, see L<Net::CIDR::Lookup|the v4 version>.

This module requires an IPv6-enabled L<Socket|Socket.pm>. As there is no way to ask for this using ExtUtils::MakeMaker, do make sure you have it.

=cut

#=head1 SYNOPSIS
# TODO flesh this out
#
#  use Net::CIDR::Lookup::IPv6;
#
#  $cidr = Net::CIDR::Lookup::IPv6->new;

=head1 METHODS

=cut

package Net::CIDR::Lookup::IPv6;
use strict;
use warnings;
use Carp;
$Carp::Verbose=1;
use Socket qw/ inet_ntop inet_pton AF_INET6 /;
use Bit::Vector;
use parent 'Net::CIDR::Lookup';

use version 0.77; our $VERSION = version->declare('v1.0.0');

=head2 add

Arguments: C<$cidr>, C<$value>

Return Value: none; dies on error

Adds VALUE to the tree under the key CIDR. CIDR must be a string containing an
IPv6 address followed by a slash and a number of network bits. Bits to the
right of this mask will be ignored.

=cut

sub add {
	my ($self, $cidr, $val) = @_;

    defined $val or croak "can't store an undef";
	my ($net, $bits) = $cidr =~ m{ ^ (.+) / (\d+) $ }ox;
    defined $net and defined $bits or croak 'CIDR syntax error: use <address>/<netbits>';
    $net = _parse_address($net);
	$self->_add($net, $bits, $val);
}

=head2 add_range

Arguments: C<$range>, C<$value>

Return Value: none; dies on error

Adds VALUE to the tree for each address included in RANGE which must be a
hyphenated range of IPv6 addresses and with the first address being numerically
smaller the second. This range will be split up into as many CIDR blocks as
necessary (algorithm adapted from a script by Dr. Liviu Daia).

=cut

sub add_range {
    my ($self, $range, $val) = @_;

    defined $val or croak "can't store an undef";
    my ($start, $end, $crud) = split /\s*-\s*/, $range;
    croak 'must have exactly one hyphen in range'
        if(defined $crud or not defined $end);
    $self->add_vec_range(_parse_address($start), _parse_address($end), $val);
}

=head2 add_vec

Arguments: C<$address>, C<$bits>, C<$value>

Return Value: none; dies on error

Like C<add()> but accepts an address as a Bit::Vector object and the network
bits as a separate integer instead of all in one string.

=cut

sub add_vec {   ## no critic (Subroutines::RequireArgUnpacking)
    # my ($self, $ip, $bits, $val) = @_;
	# Just call the recursive adder for now but allow for changes in object
    # representation ($self != $n)
    defined $_[3] or croak "can't store an undef";
	_add(@_);
}

=head2 add_str

Arguments: C<$address>, C<$bits>, C<$value>

Return Value: none; dies on error

Like C<add_vec()> but accepts an address as a packed string as returned by
C<Socket::unpack_sockaddr_in6>.

=cut

sub add_str {   ## no critic (Subroutines::RequireArgUnpacking)
    # my ($self, $ip, $bits, $val) = @_;
	shift->_add_vec(_str2vec($_[0]), _str2vec($_[1]), $_[2]);
}


=head2 add_vec_range

Arguments: C<$start>, C<$end>, C<$value>

Return Value: none; dies on error

Like C<add_range()> but accepts addresses as separate Bit::Vector objects
instead of a range string.

=cut

sub add_vec_range {
    my ($self, $start, $end, $val) = @_;
    my @chunks;

    1 == $start->Lexicompare($end)
        and croak sprintf "start > end in range %s--%s", _addr2print($start), _addr2print($end);

    _do_chunk(\@chunks, $start, $end, 127, 0);
    $self->add_vec(@$_, $val) for(@chunks);
}

=head2 add_str_range

Arguments: C<$start>, C<$end>, C<$value>

Return Value: true for successful completion; dies on error

Like C<add_vec_range()> but accepts addresses as packed strings as returned by
Socket::unpack_sockaddr_in6.

=cut

sub add_str_range { ## no critic (Subroutines::RequireArgUnpacking)
    # my ($self, $start, $end, $val) = @_;
    shift->add_vec_range(_str2vec($_[0]), _str2vec($_[1]), $_[2]);
}

=head2 lookup

Arguments: C<$address>

Return Value: value assoiated with this address or C<undef>

Looks up an IPv6 address specified as a string and returns the value associated
with the network containing it. So far there is no way to tell which network
that is though.

=cut

sub lookup {
	my ($self, $addr) = @_;

    # Make sure there is no network spec tacked onto $addr
    $addr =~ s!/.*!!;
	$self->_lookup(_parse_address($addr));
}


=head2 lookup_vec

Arguments: C<$address>

Return Value: value assoiated with this address or C<undef>

Like C<lookup()> but accepts the address as a Bit::Vector object.

=cut

sub lookup_vec { shift->_lookup($_[0]->Clone) }   ## no critic (Subroutines::RequireArgUnpacking)

=head2 lookup_str

Arguments: C<$address>

Return Value: value assoiated with this address or C<undef>

Like C<lookup()> but accepts the address as a packed string as returned by
C<Socket::unpack_sockaddr_in6>.

=cut

sub lookup_str { shift->_lookup(_str2vec($_[0])) }   ## no critic (Subroutines::RequireArgUnpacking)

=head2 to_hash

Arguments: none

Return Value: C<$hashref>

Returns a hash representation of the tree with keys being CIDR-style network
addresses.

=cut

sub to_hash {
	my ($self) = @_;
	my %result;
	$self->_walk(Bit::Vector->new(128), 0, sub {
            my $net = _addr2print($_[0]) . '/' . $_[1];
            if(defined $result{$net}) {
                confess "internal error: network $net mapped to $result{$net} already!";
            } else {
                $result{$net} = $_[2];
            }
        }
    );
	\%result;
}

=head2 walk

Arguments: C<$coderef> to call for each tree entry. Callback arguments are:

=over 1

=item C<$address>

The network address as a Bit::Vector object. The callback must not change this
object's contents, use $addr->Clone if in doubt!

=item C<$bits>

The current CIDR block's number of network bits

=item C<$value>

The value associated with this block

=back

Return Value: nothing useful

=cut

sub walk { $_[0]->_walk(Bit::Vector->new(128), 0, $_[1]) }   ## no critic (Subroutines::RequireArgUnpacking)

=head1 BUGS

=over 1

=item The IPv6 version hasn't seen any real-world testing and the unit tests
are still rather scarce, so there will probably be more bugs than listed here.

=item I didn't need deletions yet and deleting parts of a CIDR block is a bit more
complicated than anything this class does so far, so it's not implemented.

=item Storing an C<undef> value does not work and yields an error. This would be
relatively easy to fix at the cost of some memory so that's more a design
decision.

=item A consequence of the same design is also that a /0 block can't be formed.
Although it doesn't make much sense, this might happen if your input is that
weird.

=back

=head1 AUTHORS, COPYRIGHTS & LICENSE

Matthias Bethke <matthias@towiski.de>

Licensed unter the Artistic License 2.0

=head1 SEE ALSO

This module's methods are based even more loosely on L<Net::CIDR::Lite|Net::CIDR::Lite> than those of L<Net::CIDR::Lookup|Net::CIDR::Lookup>.

=cut

# Walk through a subtree and insert a network
sub _add {
	my ($node, $addr, $nbits, $val) = @_;
    my ($bit, $checksub);
    my @node_stack;

    DESCEND:
    while(1) {
	    $bit = $addr->shift_left(0);

        if(__PACKAGE__ ne ref $node) {
            return 1 if $val eq $node; # Compatible entry (tried to add a subnet of one already in the tree)
            croak "incompatible entry, found `$node' trying to add `$val'";
        }
        last DESCEND unless --$nbits;
        if(defined $node->[$bit]) {
            $checksub = 1;
        } else {
            $node->[$bit] ||= bless([], __PACKAGE__);
            $checksub = 0;
        }
        push @node_stack, \$node->[$bit];
        $node = $node->[$bit];
    }
    
    $checksub
        and defined $node->[$bit]
        and __PACKAGE__ eq ref $node->[$bit]
        and _add_check_subtree($node->[$bit], $val);

    $node->[$bit] = $val;

    # Take care of potential mergers into the previous node (if $node[0] == $node[1])
    # TODO recursively check upwards
    not @node_stack
        and defined $node->[$bit ^ 1]
        and $node->[$bit ^ 1] eq $val
        and croak 'merging two /1 blocks is not supported yet';
    while(1) {
        $node = pop @node_stack;
        last MERGECHECK unless defined $node;
        last unless(defined $$node->[0] and defined $$node->[1] and $$node->[0] eq $$node->[1]);
        $$node = $val;
    }
}

# Check an existing subtree for incompatible values. Returns false and sets the
# package-global error string if there was a problem.
sub _add_check_subtree {
    my ($root, $val) = @_;

    eval {
        $root->_walk(Bit::Vector->new(128), 0, sub {
                my $oldval = $_[2];
                $val == $oldval or die $oldval; ## no critic (ErrorHandling::RequireCarping)
            }
        );
        1;
    } or do {
        $@ and croak "incompatible entry, found `$@' trying to add `$val'";
    };
}

sub _lookup {
	my ($node, $addr) = @_;
    my $bit;
    #printf "_lookup($node, %s)\n", $addr->to_Hex;

    while(1) {
        $bit = $addr->shift_left(0);
        defined $node->[$bit] or return;
        __PACKAGE__ ne ref $node->[$bit] and return $node->[$bit];
        $node = $node->[$bit];
    }
}

# Convert a packed IPv6 address to a Bit::Vector object
sub _str2vec {   ## no critic (Subroutines::RequireArgUnpacking)
    my $b = Bit::Vector->new(128);
    $b->Chunk_List_Store(32, reverse unpack 'N4', $_[0]);
    return $b;
}

# Parse an IPv6 address and return a Bit::Vector object
sub _parse_address {   ## no critic (Subroutines::RequireArgUnpacking)
    my $b = Bit::Vector->new(128);
    $b->Chunk_List_Store(32, reverse unpack 'N4', inet_pton(AF_INET6, shift));
    return $b;
}

# Convert a Bit::Vector object holding an IPv6 address to a printable string
sub _addr2print { inet_ntop(AF_INET6, pack('N4', reverse $_[0]->Chunk_List_Read(32))) }   ## no critic (Subroutines::RequireArgUnpacking)

# Walk the tree in depth-first LTR order
sub _walk {
	my ($node, $addr, $bits, $cb) = @_;
	my ($l, $r, $rightflag);
    my @node_stack = ($node, 0, $bits);
    #print "================== WALK ==================: ", join(':',caller),"\n"; 
    while(@node_stack) {
        ($node, $rightflag, $bits) = splice @node_stack, -3; # pop 3 elems 
        #print "LOOP: stack size ".@node_stack."\n";

        $addr->Bit_On(128-$bits) if $rightflag;

        if(__PACKAGE__ eq ref $node) {
            ($l, $r) = @$node;
            #printf "Popped [%s, %s]:%s/%d\n",
            #    ($l//'') =~ /^Net::CIDR::Lookup::IPv6=/ ? '<node>' : $l//'<undef>',
            #    ($r//'') =~ /^Net::CIDR::Lookup::IPv6=/ ? '<node>' : $r//'<undef>',
            #    _addr2print($addr), $bits;
            ++$bits;

            # Check left side
            $addr->Bit_Off(128 - $bits);
            if(__PACKAGE__ eq ref $l) {
                #defined $r and print "L: pushing right node=$r, bits=$bits\n";
                defined $r and push @node_stack, ($r, 1, $bits);
                #defined $r and print "L: pushing left  node=$l, bits=$bits\n";
                push @node_stack, ($l, 0, $bits);
                #printf "L: addr=%032b (%s)\n", $addr, _addr2print($addr);
                next; # Short-circuit back to loop w/o checking $r!
            } else {
                #defined $l and printf "L: CALLBACK (%s/%d) => %s\n", _addr2print($addr), $bits, $l;
                defined $l and $cb->($addr, $bits, $l);
            }
        } else {
            # There was a right-side leaf node on the stack that will end up in
            # the "else" branch below
            #print "Found leftover right leaf $node\n";
            $r = $node;
        }

        # Check right side
        $addr->Bit_On(128 - $bits);
        if(__PACKAGE__ eq ref $r) {
            #print "R: pushing right node=$r, bits=$bits\n";
            push @node_stack, ($r, 1, $bits);
            #printf "R: addr=%032b (%s)\n", $addr, _addr2print($addr);
        } else {
            #defined $r and printf "R: CALLBACK (%s/%d) => %s\n", _addr2print($addr), $bits, $r;
            defined $r and $cb->($addr, $bits, $r);
        }
    }
}

# Split a chunk into a minimal number of CIDR blocks.
sub _do_chunk {
    my ($chunks, $start, $end, $ix1, $ix2) = @_;
    my ($xor, $prefix, $tmp_prefix) = Bit::Vector->new(128, 3);

    # Find common prefix.  After that, the bit indicated by $ix1 is 0 for $start
    # and 1 for $end. A split a this point guarantees the longest suffix.
    $xor->Xor($start, $end);
    #print STDERR "--------------------------------------------------------------------------------\n";
    #print STDERR "Start : ",$start->to_Hex,"\n";
    #print STDERR "End   : ",$end->to_Hex,"\n";
    #print STDERR "XOR   : ",$xor->to_Hex,"\n";
    --$ix1 until(-1 == $ix1 or $xor->bit_test($ix1));
    $prefix->Interval_Fill($ix1+1, 127);
    $prefix->And($prefix, $start);

    $ix2++ while($ix2 <= $ix1
            and not $start->bit_test($ix2)
            and $end->bit_test($ix2));

    #print STDERR "After loop: ix1=$ix1, ix2=$ix2, ";
    #print STDERR "Prefix: ",$prefix->to_Hex,"\n";

    if ($ix2 <= $ix1) {
        #print STDERR "Recursing with $ix1 lowbits=1 in end\n";
        $tmp_prefix->Copy($prefix);
        $tmp_prefix->Interval_Fill(0, $ix1-1);
        _do_chunk($chunks, $start, $tmp_prefix, $ix1, $ix2);

        #print STDERR "Recursing with $ix1 lowbits=0 in start\n";
        $tmp_prefix->Copy($prefix);
        $tmp_prefix->Bit_On($ix1);
        _do_chunk($chunks, $tmp_prefix, $end, $ix1, $ix2);
    } else {
        push @$chunks, [ $prefix, 127-$ix1 ];
        #printf STDERR "Result: %s/%d\n", $chunks->[-1][0]->to_Hex, $chunks->[-1][1];
    }
}

1;
