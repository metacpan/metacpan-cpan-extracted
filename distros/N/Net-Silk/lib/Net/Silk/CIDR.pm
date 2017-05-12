# Use of the Net-Silk library and related source code is subject to the
# terms of the following licenses:
# 
# GNU Public License (GPL) Rights pursuant to Version 2, June 1991
# Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013
# 
# NO WARRANTY
# 
# ANY INFORMATION, MATERIALS, SERVICES, INTELLECTUAL PROPERTY OR OTHER 
# PROPERTY OR RIGHTS GRANTED OR PROVIDED BY CARNEGIE MELLON UNIVERSITY 
# PURSUANT TO THIS LICENSE (HEREINAFTER THE "DELIVERABLES") ARE ON AN 
# "AS-IS" BASIS. CARNEGIE MELLON UNIVERSITY MAKES NO WARRANTIES OF ANY 
# KIND, EITHER EXPRESS OR IMPLIED AS TO ANY MATTER INCLUDING, BUT NOT 
# LIMITED TO, WARRANTY OF FITNESS FOR A PARTICULAR PURPOSE, 
# MERCHANTABILITY, INFORMATIONAL CONTENT, NONINFRINGEMENT, OR ERROR-FREE 
# OPERATION. CARNEGIE MELLON UNIVERSITY SHALL NOT BE LIABLE FOR INDIRECT, 
# SPECIAL OR CONSEQUENTIAL DAMAGES, SUCH AS LOSS OF PROFITS OR INABILITY 
# TO USE SAID INTELLECTUAL PROPERTY, UNDER THIS LICENSE, REGARDLESS OF 
# WHETHER SUCH PARTY WAS AWARE OF THE POSSIBILITY OF SUCH DAMAGES. 
# LICENSEE AGREES THAT IT WILL NOT MAKE ANY WARRANTY ON BEHALF OF 
# CARNEGIE MELLON UNIVERSITY, EXPRESS OR IMPLIED, TO ANY PERSON 
# CONCERNING THE APPLICATION OF OR THE RESULTS TO BE OBTAINED WITH THE 
# DELIVERABLES UNDER THIS LICENSE.
# 
# Licensee hereby agrees to defend, indemnify, and hold harmless Carnegie 
# Mellon University, its trustees, officers, employees, and agents from 
# all claims or demands made against them (and any related losses, 
# expenses, or attorney's fees) arising out of, or relating to Licensee's 
# and/or its sub licensees' negligent use or willful misuse of or 
# negligent conduct or willful misconduct regarding the Software, 
# facilities, or other rights or assistance granted by Carnegie Mellon 
# University under this License, including, but not limited to, any 
# claims of product liability, personal injury, death, damage to 
# property, or violation of any laws or regulations.
# 
# Carnegie Mellon University Software Engineering Institute authored 
# documents are sponsored by the U.S. Department of Defense under 
# Contract FA8721-05-C-0003. Carnegie Mellon University retains 
# copyrights in all material produced under this contract. The U.S. 
# Government retains a non-exclusive, royalty-free license to publish or 
# reproduce these documents, or allow others to do so, for U.S. 
# Government purposes only pursuant to the copyright license under the 
# contract clause at 252.227.7013.

package Net::Silk::CIDR;

use strict;
use warnings;
use Carp;

use Net::Silk qw( :basic );

use Scalar::Util qw( refaddr );

use overload (
  '""'  => \&as_str,
  '<>'  => \&_fh_iter,
  'eq'  => \&_eq,
  '=='  => \&_eq,
  'ne'  => \&_ne,
  '!='  => \&_ne,
  '<=>' => \&_cmp,
  'cmp' => \&_cmp,
);

my %Attr;

# _bit_hosts($ip, $prefix)
sub _bit_hosts {
  my $prefix = (ref $_[0])->SILK_IPADDR_BITS;
  2**($prefix - $_[1]);
}

# _cidr_mask($ip, $prefix)
sub _cidr_mask { $_[0] & _bit_mask(@_) }

# _bit_mask($ip, $prefix)
sub _bit_mask  {
  my $max = (ref $_[0])->SILK_IPADDR_MAX;
  ~($max >> $_[1]) & $max;
}


# begin methods

sub new {
  my $class = shift;
  my($ip, $prefix);
  if (@_ == 1) {
    if (ref $_[0] eq 'ARRAY' || UNIVERSAL::isa($_[0], $class)) {
      ($ip, $prefix) = @{$_[0]};
    }
    else {
      ($ip, $prefix) = split(/\//, $_[0]);
      $prefix = 32 unless defined $prefix;
    }
  }
  else {
    ($ip, $prefix) = @_;
  }
  defined $ip && defined $prefix
    or croak "ip and prefix bits required";
  croak "cidr prefix bits out of range"
    unless ($prefix >= 0 || $prefix <= $class->SILK_IPADDR_BITS);
  $ip = SILK_IPADDR_CLASS->new($ip);
  $ip = _cidr_mask($ip, $prefix);
  my $self = [$ip, $prefix];
  bless $self, $class;
}

sub ip     { shift->[0] }
sub prefix { shift->[1] }
*bits = *prefix;

sub first { shift->[0] }

sub last {
  my $self = shift;
  $self->[0] + (_bit_hosts($self->[0], $self->[1]) - 1)
}

sub cardinality { _bit_hosts(@{shift()}) }

sub contains {
  my($self, $ip) = @_;
  $self->first <= $ip && $self->last >= $ip;
}

sub iter { SILK_IPWILDCARD_CLASS->new(shift->as_str)->iter }

sub iter_bag { SILK_IPWILDCARD_CLASS->new(shift->as_str)->iter_bag }

sub _fh_iter {
  my $self = shift;
  my $attr = $Attr{refaddr($self)} ||= {};
  my $iter = $attr->{fh_iter} ||= $self->iter;
  if (wantarray) {
    delete $attr->{fh_iter};
    return $iter->();
  }
  else {
    while ($_ = $iter->()) {
      return $_;
    }
    delete $Attr{refaddr($self)}->{fh_iter};
    return;
  }
}

sub as_range {
  my $self = shift;
  SILK_RANGE_CLASS->new($self->first, $self->last);
}

sub as_str { join('/', @{shift()}) }

sub _iter_ranges {
  my $class = shift;
  my $cidr_iter = shift;
  my($current, $tmp);
  my $range_iter = sub {
    while (my $cidr = $cidr_iter->()) {
      if (!$current) {
        $current = $cidr->as_range;
        next;
      }
      else {
        my $first = $cidr->[0];
        if ($first - $current->[1] == 1) {
          $current->[1] = $cidr->last;
          next;
        }
        else {
          $tmp = $current;
          $current = $cidr->as_range;
          return $tmp;
        }
      }
    }
    if ($current) {
      $tmp = $current;
      $current = undef;
      return $tmp;
    }
  };
  sub {
    if (wantarray) {
      my @ranges;
      while (my $r = $range_iter->()) {
        push(@ranges, $r);
      }
      return @ranges;
    }
    else {
      while (my $r = $range_iter->()) {
        return $r;
      }
    }
  };
}

sub _eq {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  $self->ip == $other->ip && $self->prefix == $other->prefix;
}

sub _ne {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  $self->ip != $other->ip || $self->prefix != $other->prefix;
}

sub _cmp {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  ($self->ip <=> $other->ip) || ($self->prefix <=> $other->prefix);
}

sub DESTROY {
  delete $Attr{refaddr(shift)};
}

1;

__END__

=head1 NAME

Net::Silk::CIDR - SiLK IP CIDR class

=head1 SYNOPSIS

  use Net::Silk::CIDR;

  my $r = Net::Silk::CIDR->new('1.1.1.0' => 27); # or "1.1.1.0/27"

  $r->contains("1.1.1.2"); # true

  print "$r\n";                            # 1.1.1.0/27
  print join('/', $r->ip, $r->prefix), "\n"; # 1.1.1.0/27
  print join('/', @$r, "\n";               # 1.1.1.0/27

  my $size = $r->cardinality; # 32

  use Net::Silk::IPSet;
  my $s = Net::Silk::IPSet->load("my.set");
  my $iter = $s->iter_cidr;
  while (my $r = $iter->()) {
    ... # $r is a Net::Silk::CIDR
  }

  use Net::Silk::Pmap;
  my $s = Net::Silk::Pmap->load("my.pmap");
  my $iter = $s->iter_cidr;
  while (my($k, $v) = each %$s) {
    ... # $k is a Net::Silk::CIDR
  }

=head1 DESCRIPTION

C<Net::Silk::CIDR> is a lightweight wrapper around a CIDR block
specified by an IP and prefix bits. It is returned by iterators in
L<Net::Silk::IPSet>, L<Net::Silk::Pmap>, and L<Net::Silk::IPWildcard>.

=head1 METHODS

=over

=item new($addr, $prefix)

=item new([$addr, $prefix])

=item new($string)

Returns a new C<Net::Silk::CIDR> object represented by the given IP
base and prefix bits. The two values can be provided either as separate
arguments, in an array ref, or a string representation.

=item ip()

Return the base of this CIDR as a L<Net::Silk::IPAddr>. This can
alternately be accessed via C<$r-E<gt>[0]>.

=item prefix()

Return the prefix bits of this CIDR. This can alternately be accessed
via C<$r-E<gt>[1]>.

=item first()

Return the first address in the CIDR range, same as C<ip()>.

=item last()

Return the last address in the CIDR range.

=item carinality()

Return the number of elements in this block.

=item contains($item)

Return whether or not the given item is contained in this block.

=item as_range()

Returns a L<Net::Silk::Range> representing this block.

=item as_str()

Return a string in the form of C<"ip/prefix">. This method gets invoked
automatically when the block is used in string context.

=item iter()

Return a sub ref that iterates over all elements of this block. Treating
the object like a filehandle C<E<lt>$rE<gt>> yields the same results.

=back

=head1 OVERLOADED OPERATORS

The following operators are overloaded:

  <>     ""
  eq     ==
  ne     !=
  cmp    <=>

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
