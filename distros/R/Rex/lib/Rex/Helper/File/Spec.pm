#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Helper::File::Spec;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use English qw(-no_match_vars);

require File::Spec::Unix;
require File::Spec::Win32;

sub AUTOLOAD { ## no critic (ProhibitAutoloading)
  my ( $self, @args ) = @_;

  ( my $method ) = our $AUTOLOAD =~ /::(\w+)$/msx;

  my $file_spec_flavor = 'File::Spec::Unix';

  if ( $OSNAME eq 'MSWin32' && !Rex::is_ssh() ) {
    $file_spec_flavor = 'File::Spec::Win32';
  }

  return $file_spec_flavor->$method(@args);
}

1;
