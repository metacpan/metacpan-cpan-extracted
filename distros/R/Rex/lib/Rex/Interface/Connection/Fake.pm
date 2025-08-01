#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Interface::Connection::Fake;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Interface::Connection::Base;

use base qw(Rex::Interface::Connection::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $that->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

sub error { }

sub connect {
  my ( $self, %option ) = @_;
  $self->{server} = $option{server};
}

sub disconnect               { }
sub get_connection_object    { my ($self) = @_; return $self; }
sub get_fs_connection_object { my ($self) = @_; return $self; }
sub is_connected             { return 1; }
sub is_authenticated         { return 1; }

sub get_connection_type { return "Local"; }

1;
