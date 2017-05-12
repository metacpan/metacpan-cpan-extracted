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

package Net::Silk::Range;

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

sub _split_args {
  my $class = shift;
  my($lo, $hi);
  if (@_ == 1) {
    eval { ($lo, $hi) = @{$_[0]} };
    if ($@) {
      ($lo, $hi) = split(/-/, $_[0]);
    }
  }
  else {
    ($lo, $hi) = @_;
  }
  defined $lo && defined $hi
    or croak "first and last members of range required";
  ($lo, $hi);
}

sub new {
  my $class = shift;
  my($lo, $hi) = $class->_split_args(@_);
  eval {
    $lo = SILK_IPADDR_CLASS->new($lo);
    $hi = SILK_IPADDR_CLASS->new($hi);
  };
  if ($@) {
    eval {
      $lo = SILK_PROTOPORT_CLASS->new($lo);
      $hi = SILK_PROTOPORT_CLASS->new($hi);
    };
    if ($@) {
      croak "low and hi vals are not ip addresses or proto/port pairs";
    }
  }
  ($hi, $lo) = ($lo, $hi) if $lo > $hi;
  my $self = [$lo, $hi];
  bless $self, $class;
}

sub first { shift->[0] }
sub last  { shift->[1] }

sub cardinality {
  my $self = shift;
  $self->last->num - $self->first->num + 1;
}

sub contains {
  my($self, $ip) = @_;
  $self->[0] <= $ip && $self->[1] >= $ip;
}

sub iter {
  my $self = shift;
  my($cursor, $last) = ($self->first, $self->last);
  my $tmp;
  sub {
    if (wantarray) {
      my @items;
      while ($cursor <= $last) {
        push(@items, $cursor);
        ++$cursor;
      }
      return @items;
    }
    while ($cursor <= $last) {
      $tmp = $cursor;
      ++$cursor;
      return $tmp;
    }
  };
}

sub iter_bag {
  my $self = shift;
  my($cursor, $last) = ($self->first, $self->last);
  my $tmp;
  sub {
    if (wantarray) {
      my @items;
      while ($cursor <= $last) {
        push(@items, [$cursor, 1]);
        ++$cursor;
      }
      return @items;
    }
    while ($cursor <= $last) {
      $tmp = $cursor;
      ++$cursor;
      return [$tmp, 1];
    }
  };
}

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

sub _eq {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  $self->first == $other->first && $self->last == $other->last;
}

sub _ne {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  $self->first != $other->first || $self->last != $other->last;
}

sub _cmp {
  my($self, $other) = @_;
  $other = (ref $self)->new($other) unless UNIVERSAL::isa($other, ref $self);
  # larger cardinality comes first (for pmap compatibility)
  ($self->first <=> $other->first) ||
  ($other->cardinality <=> $self->cardinality);
}

sub as_cidr {
  my $self = shift;
  my @blocks;
  my $iter = SILK_IPSET_CLASS->new($self->as_str)->iter_cidr;
  while (my $block = $iter->()) {
    push(@blocks, SILK_CIDR_CLASS->new(@$block));
  }
  wantarray ? @blocks : \@blocks;
}

sub as_str {
  my $self = shift;
  join('-', $self->first, $self->last);
}

sub DESTROY {
  delete $Attr{refaddr(shift)};
}

###

1;

__END__

=head1 NAME

Net::Silk::Range - SiLK IP and proto/port range class

=head1 SYNOPSIS

  use Net::Silk::Range;

  my $r = Net::Silk::Range->new('1.1.1.1' => '1.255.255.255');
  # or could have used "1.1.1.1-1.255.255.255"

  $r->contains("1.1.1.2"); # true

  print "$r\n";                               # 1.1.1.1-1.255.255.255
  print join(' ', $r->first, $r->last), "\n"; # 1.1.1.1 1.255.255.255
  print join(' ', @$r, "\n";                  # 1.1.1.1 1.255.255.255

  my $size = $r->cardinality; # 16711423

  use Net::Silk::IPSet;
  my $s = Net::Silk::IPSet->load("my.set");
  my $iter = $s->iter_ranges;
  while (my $r = $iter->()) {
    ... # $r is a Net::Silk::Range
  }

  use Net::Silk::Pmap;
  my $s = Net::Silk::Pmap->load("my.pmap");
  my $iter = $s->iter_ranges;
  while (my($k, $v) = each %$s) {
    ... # $k is a Net::Silk::Range
  }

=head1 DESCRIPTION

C<Net::Silk::Range> is a lightweight wrapper around an IP block
specified by a first and last value. It is returned by iterators in
L<Net::Silk::IPSet>, L<Net::Silk::Pmap>, and L<Net::Silk::IPWildcard>.

=head1 METHODS

=over

=item new($first, $last)

=item new([$first, $last])

=item new($string)

Returns a new C<Net::Silk::Range> object represented by the given low
and high values. The two values can be provided either as separate
arguments, an array ref, or a string representation. The values are
L<Net::Silk::IPAddr> or L<Net::Silk::ProtoPort> objects or their string
representations.

=item first()

Return the first value in the range. This can alternately be accessed
via C<$r-E<gt>[0]>.

=item last()

Return the last value in the range. This can alternately be accessed
via C<$r-E<gt>[1]>.

=item carinality()

Return the number of elements in this range.

=item contains($item)

Return whether or not the given item is contained in this range.

=item as_cidr()

Returns an array or array ref (depending on context) of
L<Net::Silk::CIDR> blocks are covered by this range.

=item as_str()

Return a string in the form of C<"first-last">. This method gets invoked
automatically when the range is used in string context.

=item iter()

Return a sub ref that iterates over all elements of this range. Treating
the range like a filehandle C<E<lt>$rE<gt>> yields the same results.

=back

=head1 OVERLOADED OPERATORS

The following operators are overloaded:

  <>     ""
  eq     ==
  ne     !=
  cmp    <=>

=head1 SEE ALSO

L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::TCPFlags>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
