use Perlmazing qw(is_number to_number);

sub main ($$) {
	my ($aa, $bb) = ($_[0], $_[1]);
  $aa =~ s/(\d+(\.\d+)*)/to_number $1/eg;
	$bb =~ s/(\d+(\.\d+)*)/to_number $1/eg;
  my @split_a = grep {length} split /(\d+(?:\.\d+)*)/, $aa;
  my @split_b = grep {length} split /(\d+(?:\.\d+)*)/, $bb;
  my $result = 0;
  while (@split_a and @split_b) {
    my $aaa = shift @split_a;
    my $bbb = shift @split_b;
    if (is_number($aaa) and is_number($bbb)) {
      $result = $aaa <=> $bbb;
      last if $result;
    } elsif (not is_number($aaa) and not is_number($bbb)) {
      $result = lc($aaa) cmp lc($bbb);
      last if $result;
    } elsif (is_number $aaa) {
      $result = 0 <=> 1;
      last;
    } else {
      $result = 1 <=> 0;
      last;
    }
  }
  $result ||= $aa cmp $bb;
  $result;
}

