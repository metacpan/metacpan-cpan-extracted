#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Helper::Misc;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

sub get_random {
  my $count = shift;
  my @chars = @_;

  my $ret = "";
  for ( 1 .. $count ) {
    $ret .= $chars[ int( rand( scalar(@chars) - 1 ) ) ];
  }

  return $ret;
}

1;
