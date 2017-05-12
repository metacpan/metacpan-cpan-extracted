package Rex::Test::Spec::file;

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
  my $ret = 'absent';
  if ( Rex::Commands::Fs::is_symlink($self->{name}) ) {
    $ret = 'symlink';
  } elsif ( is_file($self->{name}) ) {
    $ret = 'file';
  } elsif ( is_dir($self->{name}) ) {
    $ret = 'directory';
  };
  return $ret;
}

sub mode {
  my ( $self ) = @_;
  my %ret = stat($self->{name});
  return $ret{mode};
}

sub uid {
  my ( $self ) = @_;
  my %ret = stat($self->{name});
  return $ret{uid};
}

sub owner {
  my ( $self ) = @_;
  my %ret = stat($self->{name});
  for my $user (user_list) {
    return $user if get_uid($user) == $ret{uid};
  }
}

sub readable {
  my ( $self ) = @_;
  return is_readable($self->{name});
}

sub writable {
  my ( $self ) = @_;
  return is_writable($self->{name});
}

sub mounted_on {
  my ( $self ) = @_;
  my $df = df();
  for my $dev ( keys %{$df} ) {
    return $dev if $df->{$dev}->{mounted_on} eq $self->{name};
  };
  return undef;
}

sub content {
  my ( $self ) = @_;
  return cat($self->{name}) || undef;
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->$key;
}

1;
