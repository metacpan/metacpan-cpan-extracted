#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Interface::File;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex;

sub create {
  my ( $class, $type ) = @_;

  unless ($type) {

    #$type = Rex::Commands::task()->get_connection_type;
    $type = Rex::get_current_connection()->{conn}->get_connection_type;

    #Rex::Commands::task()->get_connection_type;
    #if(Rex::is_ssh() && ! Rex::is_sudo()) {
    #  $type = "SSH";
    #}
    #elsif(Rex::is_sudo()) {
    #  $type = "Sudo";
    #}
    #else {
    #  $type = "Local";
    #}
  }

  my $class_name = "Rex::Interface::File::$type";
  eval "use $class_name;";
  if ($@) { die("Error loading file interface $type.\n$@"); }

  return $class_name->new;
}

1;
