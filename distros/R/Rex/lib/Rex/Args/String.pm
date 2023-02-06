#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Args::String;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.14.0'; # VERSION

sub get {
  my ( $class, $name ) = @_;

  my $arg = shift @ARGV;
  return $arg;
}

1;
