#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Interface::Executor::Base;

use v5.12.5;
use warnings;

our $VERSION = '1.15.0'; # VERSION

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

sub exec { die("Should be implemented by interface class."); }

sub set_task {
  my ( $self, $task ) = @_;
  $self->{task} = $task;
}

1;
