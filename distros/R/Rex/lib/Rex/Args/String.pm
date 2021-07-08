#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Args::String;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.13.4'; # VERSION

sub get {
  my ( $class, $name ) = @_;

  my $arg = shift @ARGV;
  return $arg;
}

1;
