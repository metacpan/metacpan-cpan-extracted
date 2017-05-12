#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Package;

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename;
use Rex::Apache::Build;

use vars qw(@EXPORT);

@EXPORT = qw(deploy);

sub deploy {
  my ( $name, %option ) = @_;

  unless ($name) {

    # if no file is given, use directory name
    $name = basename( getcwd() );
  }

  if ( !%option ) {
    if ( Rex::Config->get("package_option") ) {
      %option = %{ Rex::Config->get("package_option") };
    }
  }

  if ( !exists $option{type} ) {
    if ( $name =~ m/\.deb$/ ) {
      $option{type} = "deb";
    }
    elsif ( $name =~ m/\.rpm$/ ) {
      $option{type} = "rpm";
    }
    elsif ( $name =~ m/(\.tgz|\.gz)$/ ) {
      $option{type} = "tgz";
    }
    else {
      $option{type} = "tgz";
    }
  }

  my $klass = "Rex::Apache::Deploy::Package::" . $option{type};
  eval "use $klass";
  if ($@) {
    die("Error loading deploy class of type $option{type}\n");
  }

  $option{name} = $name;

  my $deploy = $klass->new(%option);
  $deploy->deploy( $name, %option );
}

sub import {

  no strict 'refs';
  for my $func (@EXPORT) {
    Rex::Logger::debug("Registering main::$func");
    *{"$_[1]::$func"} = \&$func;
  }

}
1;
