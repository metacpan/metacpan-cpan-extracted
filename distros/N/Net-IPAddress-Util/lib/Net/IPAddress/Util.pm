package Net::IPAddress::Util;

use strict;
use warnings;
use 5.010;

use overload (
    '=' => 'new',
    '""' => 'str',
    'cmp' => '_spaceship',
    '<=>' => '_spaceship',
    '+' => '_do_add',
    '-' => '_do_subtract',
    '<<' => '_shift_left',
    '>>' => '_shift_right',
    '&' => '_band',
    '|' => '_bor',
    '~' => '_neg',
);

use Carp qw( carp cluck confess );
use Exporter qw( import );
use List::MoreUtils qw( pairwise );

our %EXPORT_TAGS = (
    constr => [qw( IP n32_to_ipv4 )],
    manip  => [qw( explode_ip implode_ip ip_pad_prefix common_prefix prefix_mask ipv4_mask ipv4_flag )],
    sort   => [qw( radix_sort )],
    compat => [qw( ip2num num2ip validaddr mask fqdn )]
);

my %EXPORT_OK;
for my $k (keys %EXPORT_TAGS) {
    for my $v (@{$EXPORT_TAGS{$k}}) {
        $EXPORT_OK{$v} = 1;
    }
}

our @EXPORT_OK = keys %EXPORT_OK;

$EXPORT_TAGS{ all } = [@EXPORT_OK];

our $DIE_ON_ERROR = 0;
our $PROMOTE_N32 = 1;

our $VERSION = '3.029';

sub IP {
    return Net::IPAddress::Util->new($_[0]);
}

sub new {
    my $self = shift;
    my $class = ref($self) || $self;
    my ($address) = @_;
    unless (defined $address) {
        return ERROR("Invalid argument undef() provided");
    }
    my $normal = [ ];
    if (ref($address) eq 'ARRAY' && @$address == 16) {
        $normal = $address;
    }
    elsif (ref($address) eq 'ARRAY' && @$address == 4) {
        $normal = [ unpack 'C16', pack 'N4', @$address ];
    }
    elsif (ref $address and eval { $address->isa(__PACKAGE__) }) {
        return bless { address => $address->{ address } } => $class;
    }
    elsif ($address =~ /^(?:::ffff:)?(\d+)\.(\d+)\.(\d+)\.(\d+)$/o) {
        $normal = [
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0xff, 0xff,
            $1, $2, $3, $4
        ];
    }
    elsif ($PROMOTE_N32 and $address =~ /^\d+$/o and $address >= 0 and $address <= (2 ** 32) - 1) {
        $normal = [
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0xff, 0xff,
            unpack('C4', pack('N', $address))
        ];
    }
    elsif ("$address" =~ /^([0-9a-f]{32})$/smio) {
        my $fresh = $1;
        eval "require Math::BigInt" or return ERROR("Could not load Math::BigInt: $@");
        my $raw = Math::BigInt->from_hex("$fresh");
        while ($raw > 0) {
            my $word = $raw->copy->band(0xffffffff);
            unshift @$normal, unpack('C4', pack('N', $word));
            $raw = $raw->copy->brsft(32);
        }
        while (@$normal < 16) {
            unshift @$normal, 0;
        }
        eval "no Math::BigInt";
    }
    elsif ($address =~ /^\d+$/o) {
        eval "require Math::BigInt" or return ERROR("Could not load Math::BigInt: $@");
        my $raw = Math::BigInt->new("$address");
        while ($raw > 0) {
            my $word = $raw->copy->band(0xffffffff);
            unshift @$normal, unpack('C4', pack('N', $word));
            $raw = $raw->copy->brsft(32);
        }
        while (@$normal < 16) {
            unshift @$normal, 0;
        }
        eval "no Math::BigInt";
    }
    elsif (
        (
            scalar(grep { /::/o } split(/[[:alnum:]]+/, $address)) == 1
            or scalar(grep { /[[:alnum:]]+/ } split(/:/, $address)) == 8
        )
        and $address =~ /^([0-9a-f:]+)(?:\%.*)?$/msoi
    ) {
        # new() from IPv6 address, accepting and ignoring the Scope ID
        $address = $1;
        my ($lhs, $rhs) = split /::/, $address;
        $rhs = '' unless defined $rhs;
        my $hex = '0' x 32;
        $lhs = join '', map { substr('0000' . $_, -4) } split /:/, $lhs;
        $rhs = join '', map { substr('0000' . $_, -4) } split /:/, $rhs;
        substr($hex, 0,              length($lhs)) = $lhs;
        substr($hex, - length($rhs), length($rhs)) = $rhs;
        my @hex = split //, $hex;
        while (@hex) {
            push @$normal, hex(join('', splice(@hex, 0, 2)));
        }
    }
    elsif (length($address) == 16) {
        return bless { address => $address } => $class;
    }
    else {
        return ERROR("Invalid argument `$address', a(n) " . (ref($address) || 'bare scalar') . ' provided');
    }
    return bless { address => pack('C16', @$normal) } => $class;
}

sub is_ipv4 {
    my $self = shift;
    my @octets = unpack 'C16', $self->{ address };
    return $octets[ 10 ] == 0xff && $octets[ 11 ] == 0xff && (!grep { $_ } @octets[ 0 .. 9 ]);
}

sub ipv4 {
    my $self = shift;
    return join '.', unpack 'C4', substr($self->{ address }, -4);
}

sub as_n32 {
    my $self = shift;
    return unpack 'N', substr($self->{ address }, -4);
}

sub as_n128 {
    my $self = shift;
    my ($keep) = @_;
    my $rv;
    {
        eval "require Math::BigInt" or return ERROR("Could not load Math::BigInt: $@");
        my $accum = Math::BigInt->new('0');
        my $factor = Math::BigInt->new('1')->blsft(Math::BigInt->new('32'));
        for my $i (map { $_ * 4 } 0 .. 3) {
            $accum->bmul($factor);
            $accum->badd(Math::BigInt->new('' . unpack 'N', substr($self->{ address }, $i, 4)));
        }
        eval "no Math::BigInt" unless $keep;
        $rv = $keep ? $accum : "$accum";
    }
    return $rv;
}

sub normal_form {
    my $self = shift;
    my $hex = join('', map { sprintf('%02x', $_) } unpack('C16', $self->{ address }));
    $hex = substr(('0' x 32) . $hex, -32);
    return lc $hex;
}

sub ipv6_expanded {
    my $self = shift;
    my $hex = $self->normal_form();
    my $rv;
    while ($hex =~ /(....)/g) {
        $rv .= ':' if defined $rv;
        $rv .= $1;
    }
    return $rv;
}

sub ipv6 {
    my $self = shift;
    if ($self->is_ipv4()) {
        return '::ffff:'.$self->ipv4();
    }
    my $iv = $self->ipv6_expanded();
    my $rv = join(':', map { (my $x = $_) =~ s/^0+//; $x ||= '0'; $x } split ':', $iv);
    $rv =~ s/[^[:xdigit:]]0(:0)+/::/;
    $rv =~ s/::+/::/g;
    return $rv;
}

sub as_str { return str(@_); }

sub as_string { return str(@_); }

sub str {
    my $self = shift;
    if ($self->is_ipv4()) {
        return $self->ipv4();
    }
    return $self->ipv6();
}

sub _spaceship {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    my $lhs = $self->{ address };
    $lhs = [ unpack 'N4', $lhs ];
    $rhs = eval { $rhs->{ address } } || pack('N4', (0, 0, 0, $rhs));
    $rhs = [ unpack 'N4', $rhs ];
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    return (1 - (2 * $swapped)) * (
        $lhs->[ 0 ] <=> $rhs->[ 0 ]
        || $lhs->[ 1 ] <=> $rhs->[ 1 ]
        || $lhs->[ 2 ] <=> $rhs->[ 2 ]
        || $lhs->[ 3 ] <=> $rhs->[ 3 ]
    );
}

sub _do_add {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    my ($pow, $mask) = $self->_pow_mask;
    my $lhs = $self->{ address };
    $lhs = [ unpack 'N4', $lhs ];
    $rhs = eval { $rhs->{ address } } || pack('N4', (0, 0, 0, $rhs));
    $rhs = [ unpack 'N4', $rhs ];
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    my @l = reverse @$lhs;
    my @r = reverse @$rhs;
    my @rv;
    for my $digit (0 .. 3) {
        my $answer = $l[$digit] + $r[$digit];
        if ($answer > (2 ** 32) - 1) {
            $r[$digit + 1] += int($answer / (2 ** 32)) if exists $r[$digit + 1];
            $answer = $answer % (2 ** 32);
        }
        push @rv, $answer;
    }
    @rv = $self->_mask_out($pow, $mask, reverse @rv);
    my $retval = Net::IPAddress::Util->new(\@rv);
    return $retval;
}

sub _do_subtract {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    my ($pow, $mask) = $self->_pow_mask;
    my $lhs = $self->{ address };
    $lhs = [ unpack 'N4', $lhs ];
    $rhs = eval { $rhs->{ address } } || pack('N4', (0, 0, 0, $rhs));
    $rhs = [ unpack 'N4', $rhs ];
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    my @l = reverse @$lhs;
    my @r = reverse @$rhs;
    my @rv;
    for my $digit (0 .. 3) {
        my $answer = $l[$digit] - $r[$digit];
        if ($answer < 0) {
            $answer += (2 ** 32) - 1;
            $r[$digit + 1] -= 1 if exists $r[$digit + 1];
        }
        push @rv, $answer;
    }
    @rv = $self->_mask_out($pow, $mask, reverse @rv);
    my $retval = Net::IPAddress::Util->new(\@rv);
    return $retval;
}

sub _shift_left {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    my ($pow, $mask) = $self->_pow_mask;
    my @l = reverse unpack('C16', $self->{ address });
    my @rv;
    for my $octet (0 .. 15) {
        $rv[$octet] += $l[$octet] << $rhs;
        if ($rv[$octet] > 255) {
            my $lsb = $rv[$octet] % 256;
            $rv[$octet + 1] += ($rv[$octet] - $lsb) >> 8 if $octet < 15;
            $rv[$octet] = $lsb;
        }
    }
    @rv = $self->_mask_out($pow, $mask, @rv);
    return Net::IPAddress::Util->new(\@rv);
}

sub _shift_right {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    my ($pow, $mask) = $self->_pow_mask;
    my @l = unpack('C16', $self->{ address });
    my @rv;
    for my $octet (0 .. 15) {
        $rv[$octet] += $l[$octet] >> $rhs;
        if (int($rv[$octet]) - $rv[$octet]) {
            my $msb = int($rv[$octet]);
            my $lsb = $rv[$octet] << $rhs;
            $rv[$octet] = $msb;
            $rv[$octet + 1] += $lsb if $octet < 15;
        }
    }
    @rv = $self->_mask_out($pow, $mask, unpack('U16', pack('N4', @rv)));
    return Net::IPAddress::Util->new(\@rv);
}

sub _band {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    ($self, $rhs) = ($rhs, $self) if $swapped;
    my $lhs = $self->{ address };
    $lhs = [ unpack 'N4', $lhs ];
    $rhs = eval { $rhs->{ address } } || pack('N4', (0, 0, 0, $rhs));
    $rhs = [ unpack 'N4', $rhs ];
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    my @l = @$lhs;
    my @r = @$rhs;
    my @rv;
    for my $octet (0 .. 3) {
        $rv[$octet] = $l[$octet] & $r[$octet];
    }
    return Net::IPAddress::Util->new(\@rv);
}

sub _bor {
    my $self = shift;
    my ($rhs, $swapped) = @_;
    ($self, $rhs) = ($rhs, $self) if $swapped;
    my $lhs = $self->{ address };
    $lhs = [ unpack 'N4', $lhs ];
    $rhs = eval { $rhs->{ address } } || pack('N4', (0, 0, 0, $rhs));
    $rhs = [ unpack 'N4', $rhs ];
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    my @l = @$lhs;
    my @r = @$rhs;
    my @rv;
    for my $octet (0 .. 3) {
        $rv[$octet] = $l[$octet] | $r[$octet];
    }
    return Net::IPAddress::Util->new(\@rv);
}

sub _neg {
    my $self = shift;
    my @n = unpack('C16', $self->{ address });
    my ($pow, $mask) = $self->_pow_mask;
    my @rv = map { 255 - $_ } @n;
    return Net::IPAddress::Util->new(\@rv);
}

sub _pow_mask {
    my $self = shift;
    my $pow = 128;
    my $mask = pack('N4', 0, 0, 0, 0);
    if ($self->is_ipv4) {
        $pow = 32;
        $mask = pack('N4', 0, 0, 0xffff, 0);
    }
    return ($pow, $mask);
}

sub _mask_out {
    my $self = shift;
    my ($pow, $mask, @rv) = @_;
    my @and = (0, 0, 0, 0);
    map { $and[ 4 - $_ ] = 0xffffffff } grep { $pow / $_ >= 32 } (1 .. 4);
    my @or = unpack('N4', $mask);
    @rv = pairwise { $a & $b } @rv, @and;
    @rv = pairwise { $a | $b } @rv, @or;
    return @rv;
}

sub ipv4_mask {
    return implode_ip(('0' x 80) . ('1' x 48));
}

sub ipv4_flag {
    return implode_ip(('0' x 80) . ('1' x 16) . ('0' x 32));
}

sub common_prefix (\@\@) {
    my ($x, $y) = @_;
    return ERROR("Something isn't right there") unless @$x == @$y;
    my @rv;
    for my $i ($[ .. $#$x) {
        if($x->[$i] == $y->[$i]) {
            push @rv, $x->[$i];
        }
        else {
            last;
        }
    }
    return @rv;
}

sub prefix_mask (\@\@) {
    my ($x, $y) = @_;
    return ERROR("Something isn't right there") unless @$x == @$y;
    my @rv;
    for my $i ($[ .. $#$x) {
        if($x->[$i] == $y->[$i]) {
            push @rv, 1;
        }
        else {
            last;
        }
    }
    return @rv;
}

sub ip_pad_prefix (\@) {
    my @array = @{$_[0]};
    for my $i (scalar(@array) .. 127) {
        push @array, 0;
    }
    return @array;
}

sub explode_ip {
    my $ip = shift;
    return split //, unpack 'B128', $ip->{ address };
}

sub implode_ip {
    return Net::IPAddress::Util->new([ unpack 'C16', pack 'B128', join '', map { split // } @_ ]);
}

sub n32_to_ipv4 { local $PROMOTE_N32 = 1; return IP(@_) }

sub ERROR {
    my $msg = @_ ? shift() : 'An error has occured';
    if ($DIE_ON_ERROR) {
        confess($msg);
    }
    else {
        cluck($msg) if $^W;
    }
    return;
}

sub radix_sort (\@) {
    # In theory, a radix sort is O(N), which beats Perl's O(N log N) by
    # a fair margin. However, it _does_ discard duplicates, so ymmv.
    shift if $_[0] eq __PACKAGE__;
    my $array = shift;
    my $from = [ map { [ unpack 'C16', $_->{ address } ] } @$array ];
    my $to;
    for (my $i = 15; $i >= 0; $i--) {
        $to = [];
        for my $card (@$from) {
            push @{$to->[ $card->[ $i ] ]}, $card;
        }
        $from = [ map { @{$_ // []} } @$to ];
    }
    my @rv = map { IP(pack 'C16', @$_) } @$from;
    return @rv;
}

sub ip2num {
    carp('Compatibility function ip2num() is deprecated') if $^W;
    my $ip = shift;
    my $self = IP($ip);
    $self &= ((2 ** 32) - 1);
    return $self->as_n32();
}

sub num2ip {
    carp('Compatibility function num2ip() is deprecated') if $^W;
    my $num = shift;
    my $self = n32_to_ipv4($num);
    return $self->str();
}

sub validaddr {
    carp('Compatibility function validaddr() is deprecated') if $^W;
    my $ip = shift;
    my @octets = split(/\./, $ip);
    return unless scalar @octets == 4;
    for (@octets) {
        return unless defined $_ && $_ >= 0 && $_ <= 255;
    }
    return 1;
}

sub mask {
    carp('Compatibility function mask() is deprecated') if $^W;
    my ($ip, $mask) = @_;
    my $self = IP($ip);
    my $nm   = IP($mask);
    return $self & $nm;
}

sub fqdn {
    carp('Compatibility function fqdn() is deprecated') if $^W;
    my $dn = shift;
    return split /\./, $dn, 2;
}

1;

__END__

=head1 NAME

Net::IPAddress::Util - Version-agnostic representation of an IP address

=head1 VERSION

Version 3.028

=head1 SYNOPSIS

    use Net::IPAddress::Util qw( IP );

    my $ipv4  = IP('192.168.0.1');
    my $ipv46 = IP('::ffff:192.168.0.1');
    my $ipv6  = IP('fe80::1234:5678:90ab');

    print "$ipv4\n";  # 192.168.0.1
    print "$ipv46\n"; # 192.168.0.1
    print "$ipv6\n";  # fe80::1234:5678:90ab

    print $ipv4->normal_form()  . "\n"; # 00000000000000000000ffffc0a80001
    print $ipv46->normal_form() . "\n"; # 00000000000000000000ffffc0a80001
    print $ipv6->normal_form()  . "\n"; # fe8000000000000000001234567890ab

    for (my $ip = IP('192.168.0.0'); $ip <= IP('192.168.0.255'); $ip++) {
        # do something with $ip
    }

=head1 DESCRIPTION

The goal of the Net::IPAddress::Util modules is to make IP addresses easy to
deal with, regardless of whether they're IPv4 or IPv6, and regardless of the
source (and destination) of the data being manipulated. The module
Net::IPAddress::Util is for working with individual addresses,
Net::IPAddress::Util::Range is for working with individual ranges of
addresses, and Net::IPAddress::Util::Collection is for working with
collections of addresses and/or ranges.

=head1 GLOBAL VARIABLES

=head2 $Net::IPAddress::Util::DIE_ON_ERROR

Set to a true value to make errors confess(). Set to a false value to make
errors cluck(). Defaults to false.

=head2 $Net::IPAddress::Util::PROMOTE_N32

Set to a true value to make new() assume that bare 32-bit (or smaller)
numbers are supposed to represent IPv4 addresses, and promote them
accordingly (i.e. to do implicitly what n32_to_ipv4() does). Set to a false
value to make new() treat all bare numbers as 128-bit numbers representing
IPv6 addresses. Defaults to false.

=head1 EXPORTABLE FUNCTIONS

=head2 explode_ip

=head2 implode_ip

Transform an IP address to and from an array of 128 bits, MSB-first.

=head2 common_prefix

Given two bit arrays (as provided by C<explode_ip>), return the truncated
bit array of the prefix bits those two arrays have in common.

=head2 prefix_mask

Given two bit arrays (as provided by C<explode_ip>), return a truncated bit
array of ones of the same length as the shared C<common_prefix> of the two
arrays.

=head2 ip_pad_prefix

Take a truncated bit array, and right-pad it with zeroes to the appropriate
length.

=head2 ipv4_mask

Returns a bitmask that can be ANDed against an IP to pull out only
the IPv4-relevant bits, that is the N32 portion with the 0xffff appended to its
front.

=head2 ipv4_flag

Returns a bitmask that can be ORed onto an N32 to make it a proper "IPv4
stored as IPv6" N128.

=head2 radix_sort

Given an array of objects, sorts them in ascending order, faster than Perl's
built-in sort command.

For those who understand the math, a radix sort is C<O(N)> instead of C<O(N
log N)> (the speed of Perl's builtin sort()), but it I<does> discard
duplicates, so ymmv. B<There are also (rare) corner cases> in which radix_sort()
can chew up so much RAM that it causes paging / swapping, which I<will> slow
down the process I<dramatically>.

Also note that this particular radix sort implementation is technically kinda
C<O(48 * N)> (even though one would normally ignore a simple multiplier factor),
so the break even point is actually nice and low (something close to 4 or more
addresses) for it to be worth the setup and teardown costs associated.

=head1 COMPATIBILITY API

=head2 ip2num

=head2 num2ip

=head2 validaddr

=head2 mask

=head2 fqdn

These functions are exportable to provide a functionally-identical API
to that provided by C<Net::IPAddress>. They will cause warnings to be issued
if they are called, to help you in your transition to Net::IPAddress::Util,
if indeed that's what you're doing -- and I can't readily imagine any other
reason you'd want to export them from here (as opposed to from Net::IPAddress)
unless that's indeed what you're doing.

=head1 EXPORT TAGS

=head2 :constr

Exports IP() and n32_to_ipv4(), both useful for creating objects based on
arbitrary external data.

=head2 :manip

Exports the functions for low-level "bit-twiddling" of addresses. You very
probably don't need these unless you're writing your own equivalent of the
Net::IPAddress::Util::Range or Net::IPAddress::Util::Collection modules.

=head2 :sort

Exports radix_sort(). You only need this if you're dealing with very large
arrays of Net::IPAddress::Util objects, and runtime is of critical concern.

=head2 :compat

Exports the Compatibility API functions listed above.

=head2 :all

Exports all exportable functions.

=head1 CONSTRUCTORS

=head2 new

Create a new Net::IPAddress::Util object, based on a well-formed IPv4 or IPv6
address string (e.g. '192.168.0.1' or 'fe80::1234:5678:90ab'), or based
on what is known by this module as the "normal form", a 32-digit hex number
(without the leading '0x').

=head2 IP

The exportable function IP() is a shortcut for Net::IPAddress::Util->new().

    my $xyzzy = Net::IPAddress::Util->new($foo);
    my $plugh = IP($foo); # Exactly the same thing, but with less typing

=head2 n32_to_ipv4

The exportable function n32_to_ipv4() converts an IPv4 address in "N32"
format (i.e. a network-order 32-bit number) into an Net::IPAddress::Util
object representing the same IPv4 address.

=head1 OVERLOADS

This module overloads a number of operators (cmp, E<lt>=E<gt>, &, |, ~,
+, -, E<lt>E<lt>, E<gt>E<gt>) in hopefully obvious ways.

=head1 OBJECT METHODS

=head2 is_ipv4

Returns true if this object represents an IPv4 address.

=head2 ipv4

Returns the dotted-quad representation of this object, or an error if it is
not an IPv4 address, for instance '192.168.0.1'.

=head2 as_n32

Returns the "N32" representation of this object (that is, a 32-bit number in
network order) if this object represents an IPv4 address, or an error if it
does not.

=head2 as_n128

Returns the "N128" representation of this object (that is, a 128-bit number in
network order).

You may supply one optional argument. If this argument is true, the return
value will be a Math::BigInt object (allowing quickish and easy math involving
two such return values), otherwise (if it is false (the default)), then the N128
number will be returned as a bare string. If your platform can handle math with
unsigned 128-bit integers, or if you will not be doing math on the results,
then I strongly recommend the latter (default / false) option for performance
reasons. In the true-argument case, you're advised to stringify the Math::BigInt
math results as soon as is practical for performance reasons -- Math::BigInt is
not "CPU free".

=head2 ipv6

Returns the canonical IPv6 string representation of this object, for
instance 'fe80::1234:5678:90ab' or '::ffff:192.168.0.1'.

=head2 ipv6_expanded

Returns the IPv6 string representation of this object, without compressing
extraneous zeroes, for instance 'fe80:0000:0000:0000:0000:1234:5678:90ab'.

=head2 normal_form

Returns the value of this object as a zero-padded 32-digit hex string,
without the leading '0x', suitable (for instance) for storage in a database,
or for other purposes where easy, fast sorting is desirable, for instance
'fe8000000000000000001234567890ab'.

=head2 '""'

=head2 str

=head2 as_str

=head2 as_string

If this object is an IPv4 address, it stringifies to the result of C<ipv4>,
else it stringifies to the result of C<ipv6>.

=head1 INTERNAL FUNCTIONS

=head2 ERROR

Either confess()es or cluck()s the passed string based on the value of
$Net::IPAddress::Util::DIE_ON_ERROR, and if possible returns undef.

=head1 LICENSE

May be redistributed and/or modified under terms of the Artistic License v2.0.

=head1 AUTHOR

PWBENNETT -- paul(dot)w(dot)bennett(at)gmail.com

=cut

