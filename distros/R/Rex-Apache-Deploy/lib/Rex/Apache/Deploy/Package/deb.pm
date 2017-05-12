#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::deb - Deploy deb package

=head1 DESCRIPTION

With this module you can deploy a Debian package.

If the package is not build yet, it will pass all the arguments to the build() function and executes the build on the local machine.

=head1 SYNOPSIS

 deploy "my-software.deb";

 deploy "my-software",
   type   => "deb",
   version => "1.0",
   # below this, it is all optional
   source  => "/path/to/your/software",
   path   => "/path/to/deploy/target",
   description   => "some description of your package",
   url        => "website of the package",
   depends      => [qw/httpd perl/],
   release      => 1,
   epoch       => 1,
   vendor      => "some vendor",
   license      => "your license for ex. GPL2",
   section      => "some/section",
   conflicts    => [qw/somepkg/],
   provides     => "some-package-name",
   arch        => "x86_64",
   target      => "linux / the platform",
   post_install  => "filename or script to run after installation",
   pre_install   => "filename or script to run before installation",
   post_uninstall => "filename or script to run after uninstall",
   pre_uninstall  => "filename or script to run before uninstall",
   exclude      => [qw/file1 file2/],
   maintainer    => "your name",
   config_files  => [qw/special files for configuration mostly for etc directory/];


=cut

package Rex::Apache::Deploy::Package::deb;

use strict;
use warnings;

use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

use Rex::Commands;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands::Upload;
use Rex::Apache::Build;
use Data::Dumper;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  if ( $self->{arch} eq "x86_64" ) {
    $self->{arch} = "amd64";
  }

  return $self;
}

sub deploy {
  my ( $self, $package_name, %option ) = @_;

  LOCAL {
    if ( !-f $package_name ) {
      $package_name =
        $self->name . "_" . $self->version . "_" . $self->arch . ".deb";

      if ( !-f $package_name ) {
        build( $self->name, %option );
      }
    }
  };

  upload $package_name, "/tmp";

  run "dpkg -i /tmp/$package_name";
  if ( $? != 0 ) {

    # try to install deps
    run "apt-get -y -f install";
    if ( $? != 0 ) {
      unlink "/tmp/$package_name";
      die("Error installing $package_name");
    }

    my $pkg = Rex::Pkg->get;
    if ( !$pkg->is_installed( $self->name ) ) {
      unlink "/tmp/$package_name";
      die("Error installing $package_name");
    }
  }

  Rex::Logger::info("Package $package_name installed.");

  unlink "/tmp/$package_name";
}

1;
