#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Args::String;

use v5.12.5;
use warnings;

our $VERSION = '1.16.0'; # VERSION

sub get {
  my ( $class, $name ) = @_;

  my $arg = shift @ARGV;
  return $arg;
}

1;
