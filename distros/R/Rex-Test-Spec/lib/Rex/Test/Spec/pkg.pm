package Rex::Test::Spec::pkg;

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

sub version {
  my ( $self ) = @_;
  my @packages = installed_packages;
  for my $p (@packages) {
    if ($p->{name} eq $self->{name}) {
      return $p->{version};
    }
  }
}

sub ensure {
  my ( $self ) = @_;
  return is_installed($self->{name}) ? 'present' : 'absent';
}

sub getvalue {
  my ( $self, $key ) = @_;
  return $self->$key;
}

1;
