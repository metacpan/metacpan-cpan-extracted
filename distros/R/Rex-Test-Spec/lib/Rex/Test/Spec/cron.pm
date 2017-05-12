package Rex::Test::Spec::cron;

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

sub getvalue {
  my ( $self, $key ) = @_;
  my @list = cron list => $self->{name} // 'root';
  return \@list;
}

1;
