#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::User;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Commands::Gather;
use Rex::Logger;

sub get {

  my $user_o = "Linux";
  if (is_freebsd) {
    $user_o = "FreeBSD";
  }
  elsif (is_netbsd) {
    $user_o = "NetBSD";
  }
  elsif (is_openbsd) {
    $user_o = "OpenBSD";
  }
  elsif ( operating_system_is("SunOS") ) {
    $user_o = "SunOS";
  }
  elsif (is_openwrt) {
    $user_o = "OpenWrt";
  }

  my $class = "Rex::User::" . $user_o;
  eval "use $class";

  if ($@) {

    Rex::Logger::info("OS not supported");
    die("OS not supported");

  }

  return $class->new;

}

1;
