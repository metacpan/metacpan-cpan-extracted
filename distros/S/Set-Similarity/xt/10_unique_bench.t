#!perl
use strict;
use warnings;

use Benchmark qw(:all);

print STDERR 'wu: ',wu(),"\n";
print STDERR 'wo: ',wo(),"\n";


cmpthese(100_000, {
        'withuniq' => sub { wu(); },
        'without' => sub { wo(); },
});

sub wu {
  my $wu = 'WithUniq';

  $wu->from_tokens(
    [qw(f o t o g r a f  )],
    [qw( p h o t o g r a p h e r)],
  );
}

sub wo {
  my $wu = 'Without';

  $wu->from_tokens(
    [qw(f o t o g r a f  )],
    [qw( p h o t o g r a p h e r)],
  );
}





{
package WithUniq;

sub from_tokens {
  my $self = shift;
  my $tokens1 = shift || [];
  my $tokens2 = shift || [];

  return $self->from_sets(
    [$self->uniq($tokens1)],
    [$self->uniq($tokens2)],
  );
}

# overlap is default
sub from_sets {
  my ($self, $set1, $set2) = @_;

  # ( A intersect B ) / min(A,B)
  return (
    $self->intersection($set1,$set2) / $self->min($set1,$set2)
  );
}

sub intersection {
  my %uniq;
  @uniq{@{$_[1]}} = ();
  scalar grep { exists $uniq{$_} } @{$_[2]};
}

sub uniq {
  my %uniq;
  @uniq{@{$_[1]}} = ();
  return keys %uniq;
}

sub min {
  (scalar(@{$_[1]}) < scalar(@{$_[2]}))
    ? scalar(@{$_[1]}) : scalar(@{$_[2]});
}


}







{
package Without;

sub from_tokens {
  my $self = shift;
  my $tokens1 = shift || [];
  my $tokens2 = shift || [];

  my %unique1;
  @unique1{@$tokens1} = ();
  my %unique2;
  @unique2{@$tokens2} = ();
  return $self->from_sets(\%unique1,\%unique2);
}

# overlap is default
sub from_sets {
  my ($self, $set1, $set2) = @_;

  # ( A intersect B ) / min(A,B)
  return (
    $self->intersection($set1,$set2) / $self->min($set1,$set2)
  );
}

sub intersection {
  scalar grep { exists ${$_[1]}{$_} } keys %{$_[2]};
}

sub min {
  (scalar(keys %{$_[1]}) < scalar(keys %{$_[2]}))
    ? scalar(keys %{$_[1]}) : scalar(keys %{$_[2]});
}


}

use List::Util qw(min);
