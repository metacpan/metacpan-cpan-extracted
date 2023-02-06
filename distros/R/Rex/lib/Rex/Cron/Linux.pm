#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Cron::Linux;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.14.0'; # VERSION

use Rex::Cron::Base;
use base qw(Rex::Cron::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

1;
