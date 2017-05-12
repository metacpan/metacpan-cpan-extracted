package Net::IP::AddrRanges;

use strict;
use warnings;
our $VERSION = '0.01';

my $BIN_THRESHOLD = 20;

my @masks_ip4 = map pack('B*', '1' x ($_ + 96) . '0' x (32 - $_)), 0 .. 32;
my %masks_ip4 = map { join('.', unpack('CCCC' ,substr($_,12))) , $_ } @masks_ip4;
my @masks_ip6 = map pack('B*', '1' x $_ . '0' x (128 - $_)), 0 .. 128;

# rule example:
#[
#            # 0000 - 0003 are out
#    '0004', # 0004 - 0018 are in
#    '0019', # 0019 - f010 are out
#    'f011', # f011 - ffff are in
#]

sub new {
    my $class = shift;
    my $self = bless [], $class;
    $self->add(@_) if @_;
    $self;
}

sub list_ranges {
    my($self) = @_;
    my @list;
    for(my $i = 0; $i < @$self; $i+=2) {
        my $min = _unpack($self->[$i]);
        my $max = exists $self->[$i + 1]
            ? _unpack(_decr($self->[$i + 1]))
            : 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff';

        push @list, $min . '-' . $max;
    }
    return @list;
}

sub _dump {
    my($self) = @_;
    warn "[\n" . join('', map _unpack($_) . "\n", @$self) ."]\n";
}

sub add {
    my $self = shift;
    for(@_) {
        my @range = _range($_) or next;
        $self->_add(@range, 0);
    }
    return $self;
}

sub subtract {
    my $self = shift;
    for(@_) {
        my @range = _range($_) or next;
        $self->_add(@range, 1);
    }
    return $self;
}

sub _add {
    my($self, $min, $max, $sub) = @_;
    
    if($max eq $masks_ip6[128]) {
        my $i = 0;
        $i++ while exists $self->[$i] && $self->[$i] lt $min;
        splice @$self, $i, @$self-$i, $sub
            ? ($i % 2 ? $min : ())
            : ($i % 2 ? () : $min);
        return;
    }

    my $out = _incr($max);

    if(not @$self) { # if emtpy
        @$self = ($min, $out);
        return;
    }

    my $i = 0;
    $i++ while exists $self->[$i] && $self->[$i] lt $min;
    my $j = $i;
    $j++ while exists $self->[$j] && $self->[$j] le $out;

    splice @$self, $i, $j-$i,
        $sub
        ? (
            $i % 2 ? $min : (),
            $j % 2 ? $out : ()
        )
        : (
            $i % 2 ? () : $min,
            $j % 2 ? () : $out
        );
}


sub find {
    my $self = shift;
    return 0 if not @$self;
    
    my $addr = _pack(shift);

    # outside
    return 0          if $addr lt $self->[0];
    return @$self % 2 if $addr ge $self->[-1];

    my $i = 0;
    if(@$self < $BIN_THRESHOLD) {
        $i++ while exists $self->[$i] && $self->[$i] le $addr;
    }
    else {
        my($l,$r)=(0, scalar @$self);

        while($l < $r) {
            $i = int(($l + $r) / 2);
            if($addr lt $self->[$i]) {
                last if $self->[$i - 1] le $addr;
                $r = $i;
            }
            else {
                $l = $i;
            }
        }
    }
    return $i % 2;
}

# Util functions below

sub _pack {
    my($addr) = @_;
    $addr =~ /:/ ? _pack_ip6($addr) : _pack_ip4($addr);
}

sub _pack_ip4 {
    my $in = shift;
    return if not $in =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
    my $str = "\x00" x 12; # 96bit padding
    for(split /\./, $in) {
        return if $_ > 255;
        $str .= pack('C', $_);
    }
    return $str;
}

sub _pack_ip6 {
    my $in = shift;
    if($in =~ /:([12]\d\d(?:\.[12]\d\d){3})$/) {
        return _pack_ip4($1);
    }
    $in =~ s{::}{':0' x (9-($in =~ tr/://))}e;
    pack 'H32',  join '',  map {('0' x (4-length)) . $_} split /:/, $in, -1;
}

sub _range {
    my($in) = @_;

    if($in =~ /-/) {
        # addr-addr
        my($min, $max) = split /-/, $in, 2;
        ($min, $max) = (_pack($min), _pack($max));
        return if not (defined $min and defined $max);
        return ($min le $max) ? ($min, $max) : ($max, $min);
    }
    elsif($in =~ /\//) {
        # addr/mask
        my($addr, $mask) = split /\//, $in, 2;
        if($addr =~ /:/) {
            $addr = _pack_ip6($addr);
            $mask = $masks_ip6[$mask];
        }
        else {
            $addr = _pack_ip4($addr);
            $mask = $mask =~ /\./ ? $masks_ip4{$mask} : $masks_ip4[$mask] or return;
        }
        return $addr & $mask, $addr | ~$mask
    }
    else {
        # addr
        my $addr = _pack($in);
        return $addr, $addr;
    }
}

sub _unpack {
    my($addr) = @_;
    ($addr & ~ $masks_ip4[0]) eq $addr
        ? _unpack_ip4($addr)
        : _unpack_ip6($addr)
        ;
}

sub _unpack_ip4 {
    join '.', unpack 'CCCC' ,substr(shift,12);
}

sub _unpack_ip6 {
    my $v6 = join ':', unpack 'H4H4H4H4H4H4H4H4', shift;
    $v6 =~ s/(^|:)0{1,3}/${1}/g; # omit leading zeroes
    $v6 =~ s/(?:(?:^|:)0){2,}(?::)?/::/; # group of zeroes
    $v6;
}

sub _incr {
    my($in) = @_;
    my $p = length($in) * 8 - 1;
    while(vec($in, $p^7, 1)) {
        vec($in, $p--^7,1) = 0;
        return $in if $p < 0;
    }
    vec($in, $p^7, 1) = 1;
    return $in;
}

sub _decr {
    my($in) = @_;
    my $p = length($in) * 8 - 1;
    while(not vec($in, $p^7, 1)) {
        vec($in, $p--^7,1) = 1;
        return $in if $p < 0;
    }
    vec($in, $p^7, 1) = 0;
    return $in;
}

package Net::IP::AddrRanges::Spanner;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub find {
    my $self = shift;
    my %result;
    for my $addr (@_) {
        while(my($k, $range) = each %$self) {
            $result{$addr}{$k} = $range->find($addr);
        }
    }
    \%result;
}

1;
__END__

=head1 NAME

Net::IP::AddrRanges - IP address ranges to match

=head1 SYNOPSIS

  use Net::IP::AddrRanges;
  
  my $ranges = Net::IP::AddrRanges->new();
  $ranges->add(
    '192.168.0.0/24',               # CIDR style
    '192.168.1.64/255.255.255.240', # netmask style
    '192.168.3.23',                 # single address
    '64::1/64',                     # IPv6 address range
    '192.168.5.23-192.168.12.3',    # from-to
  );
  $ranges->subtract('192.168.0.64/27'); # excludes this range

  $ranges->find('192.168.0.1');  # True 
  $ranges->find('192.168.0.70'); # False

=head1 DESCRIPTION

Net::IP::AddrRanges is to represent a list of IP address ranges.

=head1 METHODS

=over 4

=item new()

Construct new object. any arguments are passed to add();

=item add(@ranges)

Adds IP address ranges to the list. this accepts single, hyphenated, netmask style
and CIDR style IP address ranges.

=item subtract(@ranges)

Subtract IP address ranges from the list. this accepts same arguments as C<add()>

=item find($ip_address)

Finds passed IP address from the list. Returns true if found, false otherwise. 

=back

=head1 AUTHOR

Rintaro Ishizaki E<lt>rintaro@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Net::CIDR::Lite> - yet another

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
