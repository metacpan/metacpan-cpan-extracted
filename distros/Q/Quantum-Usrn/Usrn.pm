package Quantum::Usrn;

use strict;
use Crypt::Blowfish;
$Quantum::Usrn::VERSION = '1.00';

my $key = pack('H*', q{4d61727479205061756c6579203c6d61727479406b617365692e636f6d3e0a4a75737420416e6f74686572205065726c204861636b65720a});
my $cipher = Crypt::Blowfish->new($key);

sub _generate_noise {
  my $data = shift;
  my $x = pack('NN', rand(2**32), rand(2**32));
  my $result = $x;
  if ((~$data & $data) eq 0 and $data==int $data) {
    $result .= $x = $cipher->encrypt($x ^ pack('a4N', 'srn#', int(rand(2**32))));
    $result .= $x = $cipher->encrypt($x ^ pack('NN', $data, int(rand(2**32))));
  } else {
    $result .= $x = $cipher->encrypt($x ^ pack('a4N', 'srn$', int(rand(2**32))));
    foreach my $four ($data=~/.{1,4}/ogs) {
      $result .= $x = $cipher->encrypt($x ^ pack('a4N', $four, int(rand(2**32))));
    }
  }
  return $result;
}

sub _filter_noise {
  my $data = shift;
  my ($x, $b0, @block) = $data=~/.{8}/ogs;
  return undef unless defined $b0;
  my ($type) = substr($x ^ $cipher->decrypt($b0), 0, 4) =~ /^srn([#\$])$/;
  $x = $b0;
  return undef unless defined $type;
  my $result;
  if ($type eq '#') {
    $result = (unpack('NN', $x ^ $cipher->decrypt($block[0])))[0];
  } else {
    foreach my $block (@block) {
      my $txt = $x ^ $cipher->decrypt($block);
      $result .= substr($txt, 0, 4);
      $x = $block;
    }
  }
  return $result;
}

# When we get a 'sensible' value, we want to produce noise;
# when we get noise, we want to produce a sensible value.
# We produce our noise by encrypting the sensible information and an equal
# amount of randomness.  Since our key is private, it will look like perfect
# noise to anyone outside.
# When we get any value, we check it it looks like noise by decrypting it.
# If it decrypts, we retrieve the original value and return its compliment;
# otherwise, we encrypt it with some randomness and return our noise.

sub Usrn ($) {
  my $arg = shift;
  my $val = _filter_noise($arg);
  return defined $val ? ~$val : _generate_noise($arg);
}

sub import {
  no strict 'refs';
  *{caller().'::Usrn'} = \&Usrn;
  1;
}

1;

=head1 NAME

Quantum::Usrn - Square root of not.

=head1 SYNOPSIS

  use Quantum::Usrn;

  $noise = Usrn($value);
  $not_value = Usrn($noise);

=head1 DESCRIPTION

Provide the 'square root of not' function (Usrn), used by weird Quantum
Physicists.  Applying Usrn to a value will produce noise; applying Usrn to that
noise will produce the bitwise negation of the original value.

It all sounds a bit stange, and mostly useless.

=head1 HISTORY

On Monday 26th February 2001 I went to hear Damian Conway give his talk on
Quantum::Superpositions at London.pm.  During the talk he described the Physics
of real quamtum superpositions, and mentioned the 'square root of not' operator.
After explaining its properties (see above) he said "it is unlikely that you
will see this operator in Perl any time soon".  Well, we all know what happens
when people say things like that...

=head1 SEE ALSO

A good physics book or psychiatrist.

=head1 AUTHOR

Marty Pauley E<lt>marty@kasei.comE<gt>

=head1 COPYRIGHT

  Copyright (C) 2001  Kasei

  This program is free software; you can redistribute it and/or modify it
  under the terms of either:
  a) the GNU General Public License;
     either version 2 of the License, or (at your option) any later version.
  b) the Perl Artistic License.

  This module is distributed in the hope that it will be useful, although I
  doubt that it will be.  There is NO WARRANTY, not even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE; I can't think of any
  particular purpose that it would be fit for.

=cut
