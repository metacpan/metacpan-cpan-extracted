#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::User::Base;

use v5.12.5;
use warnings;

our $VERSION = '1.15.0'; # VERSION

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

sub lock_password {

  # Overridden in those classes that implement it
  die "lock_password is not available on this operating system";
}

sub unlock_password {

  # Overridden in those classes that implement it
  die "unlock_password is not available on this operating system";
}

1;
