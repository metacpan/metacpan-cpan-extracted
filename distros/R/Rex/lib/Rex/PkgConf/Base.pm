#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::PkgConf::Base;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

1;
