package Rex::Test::Spec::user;

use strict;
use warnings;

use Rex -base;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my ( $pkg, $file ) = caller(0);

  return $self;
}

sub ensure {
  my ( $self ) = @_;
  return get_uid($self->{name});
}

sub belong_to {
  my ( $self ) = @_;
  my @groups = user_groups($self->{name});
  return \@groups;
}

sub shell {
  my ( $self ) = @_;
  my %ret = get_user($self->{name});
  return $ret{shell};
}

sub home {
  my ( $self ) = @_;
  my %ret = get_user($self->{name});
  return $ret{home};
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->$key;
}

1;
