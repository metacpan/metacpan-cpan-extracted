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

package Net::Silk::TCPFlags;

use strict;
use warnings;
use Carp;

use vars qw( @EXPORT_OK %EXPORT_TAGS );

use base qw( Exporter );

use Scalar::Util qw( looks_like_number );

use Net::Silk qw( :basic );

use overload (
  '""'   => \&str,
  '&'    => \&and,
  '|'    => \&or,
  '^'    => \&xor,
  '~'    => \&neg,
  'eq'   => \&eq,
  'ne'   => \&ne,
  '=='   => \&eq_num,
  '!='   => \&ne_num,
  'cmp'  => \&cmp,
  '<=>'  => \&cmp,
  'int'  => \&int,
  '!'    => \&not,
);

sub new {
  my $class = shift;
  my $repr  = shift;
  if (ref $repr and UNIVERSAL::isa($repr, __PACKAGE__)) {
    $repr = $$repr;
  }
  if (looks_like_number($repr)) {
    croak("Illegal TCP flag value: $repr") if $repr < 0 || $repr > 255;
  }
  else {
    $repr = Net::Silk::TCPFlags::parse_flags($repr);
  }
  my $self = \$repr;
  bless $self, $class;
}

sub fin { ${$_[0]} & 0x01 }
sub syn { ${$_[0]} & 0x02 }
sub rst { ${$_[0]} & 0x04 }
sub psh { ${$_[0]} & 0x08 }
sub ack { ${$_[0]} & 0x10 }
sub urg { ${$_[0]} & 0x20 }
sub ece { ${$_[0]} & 0x40 }
sub cwr { ${$_[0]} & 0x80 }

sub and {
  my $self = shift;
  my $other = __PACKAGE__->new(shift);
  __PACKAGE__->new($$self & $$other);
}

sub or {
  my $self = shift;
  my $other = __PACKAGE__->new(shift);
  __PACKAGE__->new($$self | $$other);
}

sub xor {
  my $self = shift;
  my $other = __PACKAGE__->new(shift);
  __PACKAGE__->new($$self ^ $$other);
}

sub neg {
  my $self = shift;
  __PACKAGE__->new(~$$self & 0xFF);
}

sub eq {
  my $self = shift;
  shift CORE::eq $self->str();
}

sub ne {
  my $self = shift;
  shift CORE::ne $self->str();
}

sub eq_num {
  my $self = shift;
  shift == $$self;
}

sub ne_num {
  my $self = shift;
  shift != $$self;
}

sub cmp {
  my $self = shift;
  shift() <=> $$self;
}

sub int {
  my $self = shift;
  $$self;
}

sub not {
  my $self = shift;
  !$$self;
}

sub matches {
  my $self = shift;
  my($high, $mask) = Net::Silk::TCPFlags::parse_high_mask(shift);
  ($$self & $mask) == $high;
}

#sub str { shift->_str() }

#sub padded { shift->_padded() }

# in XS:
# str()
# padded()

###

use constant BITS_FIN => 0x01;
use constant BITS_SYN => 0x02;
use constant BITS_RST => 0x04;
use constant BITS_PSH => 0x08;
use constant BITS_ACK => 0x10;
use constant BITS_URG => 0x20;
use constant BITS_ECE => 0x40;
use constant BITS_CWR => 0x80;

my $TCP_FIN = __PACKAGE__->new(BITS_FIN);
my $TCP_SYN = __PACKAGE__->new(BITS_SYN);
my $TCP_RST = __PACKAGE__->new(BITS_RST);
my $TCP_PSH = __PACKAGE__->new(BITS_PSH);
my $TCP_ACK = __PACKAGE__->new(BITS_ACK);
my $TCP_URG = __PACKAGE__->new(BITS_URG);
my $TCP_ECE = __PACKAGE__->new(BITS_ECE);
my $TCP_CWR = __PACKAGE__->new(BITS_CWR);

sub TCP_FIN { $TCP_FIN }
sub TCP_SYN { $TCP_SYN }
sub TCP_RST { $TCP_RST }
sub TCP_PSH { $TCP_PSH }
sub TCP_ACK { $TCP_ACK }
sub TCP_URG { $TCP_URG }
sub TCP_ECE { $TCP_ECE }
sub TCP_CWR { $TCP_CWR }

BEGIN {

  my @Flags = qw(
    BITS_FIN
    BITS_SYN
    BITS_RST
    BITS_PSH
    BITS_ACK
    BITS_URG
    BITS_ECE
    BITS_CWR

    TCP_FIN
    TCP_SYN
    TCP_RST
    TCP_PSH
    TCP_ACK
    TCP_URG
    TCP_ECE
    TCP_CWR
  );

  @EXPORT_OK = @Flags;

  %EXPORT_TAGS = (
    flags => \@Flags,
  );

}

###

1;

__END__

=head1 NAME

Net::Silk::TCPFlags - SiLK TCP session flags

=head1 SYNOPSIS

  use Net::Silk::TCPFlags;

  my $f1 = Net::Silk::TCPFlags->new('FSRP');
  my $f2 = Net::Silk::TCPFlags->new(5);

  my $f3 = $f1 & $f2;

  $f1->syn; # true
  $f1->ack; # false

  print "flags: $f1\n";
  print "flags: $f2\n";
  print "flags: $f3\n";

  $f1->matches("fs/fsau"); # true

=head1 DESCRIPTION

C<Net::Silk::TCPFlags> objects represent the eight bits of flags
from a TCP session.

=head1 METHODS

=over

=item new($spec)

Returns a new C<Net::Silk::TCPFlags> object. The provide spec can be
another TCP flags object, a string, or an integer. If an integer is
provided it should be the 8-bit representation of the flags. If a string
is provided it should consist of a concatenation of zero or more of the
characters F, S, R, P, A, U, E, and C (upper or lower case) representing
the FIN, SYN, RST, PSH, ACK, URG, ECE, and CWR flags. Whitespace in the
string is ignored.

=item fin()

Return true if the FIN flag is set on flags, false otherwise.

=item syn()

Return true if the SYN flag is set on flags, false otherwise.

=item rst()

Return true if the RST flag is set on flags, false otherwise.

=item psh()

Return true if the PSH flag is set on flags, false otherwise.

=item ack()

Return true if the ACK flag is set on flags, false otherwise.

=item urg()

Return true if the URG flag is set on flags, false otherwise.

=item ece()

Return true if the ECE flag is set on flags, false otherwise.

=item cwr()

Return true if the CWR flag is set on flags, false otherwise.

=item matches($flagmask)

Given a string mask of the form I<high_flags/mask_flags>, return true if
the flags match I<high_flags> after being masked with I<mask_flags>,
false otherwise. Given a I<flagmask> without the slash (/), return true
if all bits in I<flagmask> are set in these flags, i.e. a I<flagmask>
without a slash is interpreted as I<flagmask/flagmask>.

=item int()

Return the numeric representation of these flags.

=item str()

Return the string representation of these flags. This method is tied to
the C<""> operator and is invoked when quoted.

=item padded()

Return the whitespace-padded string representation of these flags.

=item and($flagmask)

Logical AND with the given flags. Bound to the C<&> operator.

=item or($flagmask)

Logical OR with the given flags. Bound to the C<|> operator.

=item xor($flagmask)

Logical EXCLUSIVE OR with the given flags. Bound to the C<^> operator.

=item neg

Logical NEGATION of these flags. Bound to the C<~> operator.

=item eq($flags)

String equality with the given flags. Bound to the C<eq> operator.

=item ne($flags)

String inequality with the given flags. Bound to the C<ne> operator.

=item eq_num($flags)

Numeric equality with the given flags. Bound to the C<==> operator.

=item ne_num($flags)

Numeric inequality with the given flags. Bound to the C<!=> operator.

=item cmp($flags)

Comparison (-1, 0, 1) with the given flags. Bound to the C<cmp>
operator.

=item not()

Boolean negation. Returns true if no flags are set, false otherwise.
Bound to the C<!> operator.

=back

=head1 OPERATORS

The following operators are overloaded and work with
C<Net::Silk::TCPFlags> objects:

  ""            ==
  &             !=
  |             cmp
  ^             <=>
  ~             int
  eq            !
  ne

=head1 CONSTANTS

The following constants are available for export with the :flags key:

=over

=item TCP_FIN

A TCPFlags object iwth only the FIN flag set.

=item TCP_SYN

A TCPFlags object iwth only the SYN flag set.

=item TCP_RST

A TCPFlags object iwth only the RST flag set.

=item TCP_PSH

A TCPFlags object iwth only the PSH flag set.

=item TCP_ACK

A TCPFlags object iwth only the ACK flag set.

=item TCP_URG

A TCPFlags object iwth only the URG flag set.

=item TCP_ECE

A TCPFlags object iwth only the ECE flag set.

=item TCP_CWR

A TCPFlags object iwth only the CWR flag set.

=back

=head1 SEE ALSO


L<Net::Silk>, L<Net::Silk::RWRec>, L<Net::Silk::IPSet>, L<Net::Silk::Bag>, L<Net::Silk::Pmap>, L<Net::Silk::IPWildcard>, L<Net::Silk::Range>, L<Net::Silk::CIDR>, L<Net::Silk::IPAddr>, L<Net::Silk::ProtoPort>, L<Net::Silk::File>, L<Net::Silk::Site>, L<silk(7)>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-2016 by Carnegie Mellon University

Use of the Net-Silk library and related source code is subject to the
terms of the following licenses:

GNU Public License (GPL) Rights pursuant to Version 2, June 1991
Government Purpose License Rights (GPLR) pursuant to DFARS 252.227.7013

NO WARRANTY

See GPL.txt and LICENSE.txt for more details.

=cut
