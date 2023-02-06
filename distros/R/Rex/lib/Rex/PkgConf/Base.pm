#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::PkgConf::Base;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.14.0'; # VERSION

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

1;
