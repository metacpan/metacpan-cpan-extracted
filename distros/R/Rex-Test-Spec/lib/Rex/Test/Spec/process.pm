package Rex::Test::Spec::process;

use strict;
use warnings;

use Rex -base;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my ( $pkg, $file ) = caller(0);
  $self->doit;
  return $self;
}

sub doit {
  my ( $self ) = @_;
  for my $process ( ps() ) {
    if ( $process->{command} =~ s/$self->{name}/ ) {
      $self->{ps} = $process;
    }
  }
}
sub getvalue {
  my ( $self, $key ) = @_;
  return $self->{ps}->{$key};
}

1;
