#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Args::Integer;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.14.0'; # VERSION

use Rex::Logger;

sub get {
  my ( $class, $name ) = @_;

  my $arg = shift @ARGV;

  if ( $arg =~ m/^\d+$/ ) {
    return $arg;
  }

  Rex::Logger::debug("Invalid argument for $name");

  return;
}

1;
