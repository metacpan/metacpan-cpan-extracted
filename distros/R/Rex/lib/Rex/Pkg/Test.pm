#
# (c) Ferenc Erki <erkiferenc@gmail.com>
#

package Rex::Pkg::Test;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Pkg::Base;
use base qw(Rex::Pkg::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless $self, $proto;

  $self->{commands} = { install => 'echo %s' };

  return $self;
}

1;
