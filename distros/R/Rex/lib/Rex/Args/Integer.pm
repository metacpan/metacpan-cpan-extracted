#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Args::Integer;

use v5.12.5;
use warnings;

our $VERSION = '1.16.0'; # VERSION

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
