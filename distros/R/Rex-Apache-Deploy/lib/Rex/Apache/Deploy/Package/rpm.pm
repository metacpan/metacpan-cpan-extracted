#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::rpm - Deploy rpm package

=head1 DESCRIPTION

With this module you can deploy a RedHat package.

If the package is not build yet, it will pass all the arguments to the build() function and executes the build on the local machine.

=head1 SYNOPSIS

 deploy "my-software.rpm";

 deploy "my-software",
   type   => "rpm",
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

package Rex::Apache::Deploy::Package::rpm;

use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

use strict;
use warnings;

use Rex::Commands;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands::Upload;
use Rex::Apache::Build;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  $self->{release} ||= 1;

  return $self;
}

sub deploy {
  my ( $self, $package_name, %option ) = @_;

  LOCAL {
    if ( !-f $package_name ) {
      $package_name =
          $self->name . "-"
        . $self->version . "-"
        . $self->release . "."
        . $self->arch . ".rpm";

      if ( !-f $package_name ) {
        build( $self->name, %option );
      }
    }
  };

  upload $package_name, "/tmp";

  run "rpm -U /tmp/$package_name";
  if ( $? != 0 ) {
    die("Error installing $package_name");
  }

  Rex::Logger::info("Package $package_name installed.");

  unlink "/tmp/$package_name";
}

1;
