#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Pkg::SunOS::pkg;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Helper::Run;
use Rex::Commands::File;
use Rex::Pkg::SunOS;

use base qw(Rex::Pkg::SunOS);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  $self->{commands} = {
    install           => 'pkg install -q --accept %s',
    install_version   => 'pkg install -q --accept %s',
    remove            => 'pkg uninstall -r -q %s',
    update_package_db => 'pkg refresh',
  };

  return $self;
}

sub get_installed {
  my ($self) = @_;

  my @lines = i_run "pkg info -l";

  my @pkg;

  my ( $version, $name );
  for my $line (@lines) {
    if ( $line =~ m/^$/ ) {
      push(
        @pkg,
        {
          name    => $name,
          version => $version,
        }
      );
      next;
    }

    if ( $line =~ m/Name: .*\/(.*?)$/ ) {
      $name = $1;
      next;
    }

    if ( $line =~ m/Version: (.*)$/ ) {
      $version = $1;
      next;
    }
  }

  return @pkg;
}

1;
