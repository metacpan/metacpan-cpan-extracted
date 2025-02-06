#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Pkg::Ubuntu;

use v5.12.5;
use warnings;

our $VERSION = '1.16.0'; # VERSION

use Rex::Pkg::Debian;

use base qw(Rex::Pkg::Debian);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

1;
