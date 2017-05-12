package Rex::Test::Spec::iptables;

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

# TODO: _rules_exists
sub getvalue {
  my ( $self, $key ) = @_;
  my @list = iptables_list();
  return \@list;
}

1;
