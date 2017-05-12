#!perl
use strict;
use warnings;

use Benchmark qw(:all);

my $arrayref = [qw(a b c d e)];
my %hash;
@hash{@$arrayref} = ();


cmpthese(1_000_000, {
        'uniq' => sub { uniq($arrayref); },
        'keys' => sub { _keys(\%hash); },
});

sub uniq {
  my %uniq; 
  @uniq{@{$_[0]}} = ();
  #my @keys = keys %uniq;
  return (keys %uniq); 
}

sub _keys {
  return keys %{$_[0]};

}