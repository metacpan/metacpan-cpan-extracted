#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Helper::URI;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

sub encode {
  my ($part) = @_;
  $part =~ s/([^\w\-\.\@])/_encode_char($1)/eg;
  return $part;
}

sub _encode_char {
  my ($char) = @_;
  return "%" . sprintf "%lx", ord($char);
}

1;
