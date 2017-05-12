#===============================================================================
#      PODNAME:  Net::IP::Identifier::Net
#     ABSTRACT:  subclass Net::IP to add some functionality
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sun Jul 20 17:48:21 PDT 2014
#===============================================================================

use 5.002;
use strict;
use warnings;

package Net::IP::Identifier::Net;
use parent 'Net::IP';

use Math::BigInt;
use Carp;

our $VERSION = '0.111'; # VERSION

use overload '""' => \&print;

# Accept any of:
#   Net::IP::Identifier::Net object or class
#   Net::IP                  object
sub new {
    my ($class, $net) = @_;

    croak "Must have exactly one argument to 'new'\n" if (@_ != 2);
    if (ref $net) {
        return $net if (ref $net eq __PACKAGE__); # already correct

        # it's an object, but wrong kind
        my $src_str;
        $src_str = $net->src_str if ($net->can('src_str'));
        bless $net, $class;   # rebless to this package
        # make sure we have a source string
        $net->src_str($src_str || $net->print);
        return $net;
    }
    my $self = $class->SUPER::new($net);
    bless $self, $class;    # rebless to this package
    $self->src_str($net);   # set the source string

    return $self;
}

sub src_str {
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->{src_str} = $new;
    }
    return $self->{src_str};
}

# print an int as a dotted decimal quad
sub int_to_ip {
    my ($self, $int, $version) = @_;

    $version ||= $self->version || 4;
    my @parts;
    if ($version eq '6') {
        while ($int or @parts < 8) {
            unshift @parts, $int & 0xffff;
            $int >>= 16;
        }
        my $addr = join(':', map { sprintf "%x", $_ } @parts);
        return Net::IP::ip_compress_address($addr, 6);
    }

    # else IPv4
    while ($int or @parts < 4) {
        unshift @parts, $int & 0xff;
        $int >>= 8;
    }
    return join('.', @parts);
}

# split a range at the binary changeover point
sub _split_range {
    my ($self, $idx, $low, $high) = @_;

    no warnings 'recursion';    # IPv6 requires at least 128 levels

if (0) {
 printf "idx $idx, low %s, high %s\n",
  $self->int_to_ip($low),
  $self->int_to_ip($high);
}

    if ($high <= $low) {
        return Net::IP::Identifier::Net->new($self->int_to_ip($low));
    }
    my $mask = Math::BigInt->new(2);
    $mask->bpow($idx);
    $mask--;
    while ($idx and ($high ^ $low) <= $mask) {  # find first mask where different bit is outside it
        $mask->brsft(1);
        $idx--;
    }
    $mask->blsft(1);    # undo one shift
    $mask += 1;
    $idx++;
    if (($mask & $low) ==  0 and
        ($mask & $high) == $mask) {
        $low = $self->int_to_ip($low);
        $high = $self->int_to_ip($high);
        return Net::IP::Identifier::Net->new("$low - $high");
    }

    croak sprintf "ran out of indexes: 0x%x-0x%x\n", $low, $high if($idx <= 0);

    # need to split
    my $new_split;
    do {
        $new_split = ($low & ~$mask);
        $mask >>= 1;
        $new_split += $mask + 1;
        $idx--;
    } while ($new_split > $high and $idx >= 0);

    my @low = $self->_split_range($idx, $low, $new_split - 1);
    my @high = $self->_split_range($idx, $new_split, $high);

    return(@low, @high);
}

# method to convert range into cidrs
sub range_to_cidrs {
    my ($self) = @_;

    return $self if ($self->prefixlen); # don't need to split

    return $self->_split_range(
        $self->masklen - 1,
        $self->intip,
        $self->last_int);
}

my $zero_v4 = '0' x 32;
my $zero_v6 = '0' x 128;
# return the length of inverse of the prefixlen, the length of the 1s in the mask
#   always returns a value, unlike prefixlen.  If not on an even binary
#   boundary, the masklen represents a big enough CIDR that the range fits
#   in it
sub masklen {
    my ($self) = @_;

    my $len = $self->version == 6 ? 128 : 32;
    # xor with zero mask also to ensure proper upper bits
    my $differ = $self->binip ^ $self->last_bin ^ ($self->version == 6 ? $zero_v6 : $zero_v4);
    my $idx = index($differ, '1');
    return 0 if $idx < 0;
    return $len - $idx;
}

# return the masked portion of the IP (upper part)
sub masked_ip {
    my ($self) = @_;

    my $len = $self->version == 6 ? 128 : 32;
    return substr($self->binip, 0, $len - $self->masklen);
}

# override print: bare IP (without prefixlen) for single IPs or network
# with prefixlength if CIDR, or as range if not single and not CIDR
sub print {
    my ($self) = @_;

    return $self->ip if ($self->ip eq $self->last_ip);
    if (defined $self->prefixlen) {
        if ($self->version eq 6) {
            return $self->SUPER::print;
        }
        return $self->ip . '/' . $self->prefixlen;
    }
    return $self->ip . '-' . $self->last_ip;
}

# return ->ip, but compress if IPv6
sub compressed_ip {
    my ($self) = @_;

    return Net::IP::ip_compress_address($self->ip, $self->version);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::Net - subclass Net::IP to add some functionality

=head1 VERSION

version 0.111

=head1 SYNOPSIS

  use Net::IP::Identifier::Net;

  my $net = Net::IP::Identifier::Net->new( IP );

=head1 DESCRIPTION

B<Net::IP::Identifier::Net> subclasses B<Net::IP>.  IP can be any of the
forms accepted by B<Net::IP>.

Stringification is provided, and uses the B<print> method.

=head2 Methods

=over

=item new( IP )

Creates a new Net::IP::Identifier::Net object.  'IP' can be a Net::IP or a
Net::IP::Identifier::Net object, or it can be any of the string formats
acceptable to Net::IP.  If 'IP' is a Net::IP::Identifier::Net, it is
immediately returned as the object.  If 'IP' is a string, it is saved as
the B<src_str>.  If 'IP' is a Net::IP object, the B<print> method is called
to create the B<src_str>.

=item src_str( [ string ] )

The string that created the object.

=item int_to_ip( $int, [ 4 | 6 ] );

Converts an integer (or a Math::BigInt) to an IP (v4 or v6) address.  If
not defined, the version (second argument) is set to 4.

=item range_to_cidrs

If B<$net> is a netblock, it may be specified by a range (like N.N.N.N -
M.M.M.M) which may or may not be representable by a single CIDR
(N.N.N.N/M).  This method returns an array of B<Net::IP::Identifier::Net>
objects that span the original range.  If B<$net> is representable by a
single CIDR, the returned array simply contains the original B<$net>.

=item masklen

Similar to Net::IP->prefixlen, but always returns a value, unlike
prefixlen.  If the netblock doesn't span an even binary boundary, the
return value represents a big enough range that the netblock fits in it.

=item masked_ip

Returns a string of 1's and 0's that are the starting IP address of B<$net>
masked with the inverse of the netmask.  This means you get the upper
significant bits (the bits that don't change within this netblock).  The
lower bits are removed.

=item print

Override of Net::IP->print, returns a string.  For Net::IP::Identifier::Net
objects which represent a single IP, the string is a dotted decimal quad
(N.N.N.N).  If B<$ip> represents a netblock, the string is a CIDR
(N.N.N.N/W) if possible, otherwise it is a range (N.N.N.N - N.N.N.N).  IPv6
addresses are compressed when possible, but IPv4 are not.

Note that Net::IP->print adds '/32' to single IPs, and it compresses CIDRs
if possible (like N.N/16).

This method is used for stringifying the object.

=item my $str = $net->compressed_ip

Returns a string.  Calls the Net::IP::ip_compress_address() function.

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
