package Rex::Test::Spec::port;

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
  my @ret = grep { $_->{state} eq 'LISTEN' and $_->{local_addr} =~ m/:$self->{name}$/ } netstat();
  $self->{ret} = \@ret;
}

sub proto {
  my ( $self ) = @_;
  return $self->{ret}->{proto};
}

sub bind {
  my ( $self ) = @_;
  return shift split(/:/, $self->{ret}->{local_addr});
}

sub command {
  my ( $self ) = @_;
  return $self->{ret}->{command};
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->$key;
}

1;
