#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::tgz - Deploy tgz package

=head1 DESCRIPTION

With this module you can deploy a TGZ packages.

If the package is not build yet, it will pass all the arguments to the build() function and executes the build on the local machine.

=head1 SYNOPSIS

 deploy "my-software.tgz";

 deploy "my-software",
   type   => "rpm",
   version => "1.0",
   # below this, it is all optional
   source  => "html",
   path   => "/var/www/html";

=cut

package Rex::Apache::Deploy::Package::tgz;

use strict;
use warnings;

use Rex::Apache::Build;
use Rex::Commands;
use Rex::Commands::Upload;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Apache::Deploy::Package::Base;
use base qw(Rex::Apache::Deploy::Package::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

sub deploy {
  my ( $self, $package_name, %option ) = @_;

  LOCAL {
    if ( !-f $package_name ) {
      $package_name = $self->name . "-" . $self->version . ".tar.gz";

      if ( !-f $package_name ) {
        build( $self->name, %option );
      }
    }
  };

  upload $package_name, "/tmp";

  my $to = $self->prefix;
  run "tar -C $to -xzf /tmp/$package_name";
  if ( $? != 0 ) {
    die("Error installing $package_name");
  }

  Rex::Logger::info("Package $package_name installed.");

  unlink "/tmp/$package_name";
}

1;
