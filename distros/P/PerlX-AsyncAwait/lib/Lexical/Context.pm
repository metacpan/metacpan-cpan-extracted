package Lexical::Context;

use strictures 2;
use B qw(svref_2object);
use Moo;

has code => (is => 'ro', required => 1);

has _pad_indices => (is => 'lazy', builder => sub {
  my ($self) = @_;
  my @b_pn = svref_2object($self->code)->PADLIST->ARRAYelt(0)->ARRAY;
  return +{
    map +($b_pn[$_]->PV => $_),
      grep {
        my $b_pn = $b_pn[$_];
        $b_pn->can('PV') and do {
          my $pn = $b_pn->PV;
          defined($pn) and length($pn) and $pn ne '&'
        };
      } 0..$#b_pn
  };
});

sub _current_pad {
  my ($self) = @_;
  return (svref_2object($self->code)->PADLIST->ARRAY)[-1]->ARRAY;
}

sub get_pad_values {
  my ($self) = @_;
  my $pad_indices = $self->_pad_indices;
  my @curpad = $self->_current_pad;
  return +{
    map +($_ => $curpad[$pad_indices->{$_}]->object_2svref),
      keys %$pad_indices
  };
}

sub set_pad_values {
  my ($self, $new_values) = @_;
  my $pad_indices = $self->_pad_indices;
  my @curpad = $self->_current_pad;
  foreach my $name (keys %$new_values) {
    my $pad_value = $curpad[$pad_indices->{$name}]->object_2svref;
    if ($name =~ /^\$/) {
      ${$pad_value} = ${$new_values->{$name}};
    } elsif ($name =~ /^\@/) {
      @{$pad_value} = @{$new_values->{$name}};
    } elsif ($name =~ /^\%/) {
      %{$pad_value} = %{$new_values->{$name}};
    }
  }
  return;
}

1;
