#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Interface::Executor;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Data::Dumper;

sub create {
  my ( $class, $type ) = @_;

  unless ($type) {
    $type = "Default";
  }

  my $class_name = "Rex::Interface::Executor::$type";
  eval "use $class_name;";
  if ($@) { die("Error loading file interface $type.\n$@"); }

  return $class_name->new;

}

1;
