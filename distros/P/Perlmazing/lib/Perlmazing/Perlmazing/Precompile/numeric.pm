use Perlmazing qw(is_number);
use version;

sub main ($$) {
	my ($aa, $bb) = ($_[0], $_[1]);
  if (is_number $aa and is_number $bb) {
    my $result = $aa <=> $bb;
    unless ($result) {
      $result = length($aa) <=> length($bb);
    }
    return $result;
  }
  my @split_a = grep {length} split /(\d+(?:\.\d+)*)/, $aa;
  my @split_b = grep {length} split /(\d+(?:\.\d+)*)/, $bb;
  my $result = 0;
  while (@split_a and @split_b) {
    my $oa = my $aaa = shift @split_a;
    my $ob = my $bbb = shift @split_b;
    if (_is_numeric($aaa) and _is_numeric($bbb)) {
      # All of this is necessary because apparently version->parse($aaa) <=> version->parse($bbb) fails with things like "2.9" vs "2.13.1",
      my $max_length = 0;
      for my $i ($aaa, $bbb) {
        my @parts = split /\./, $i;
        for my $number (@parts) {
          my $length = length $number;
          $max_length = $length if $length > $max_length;
        }
      }
      if ($aaa =~ /\./ or $bbb =~ /\./) {
        my @parts_a = split /\./, $aaa;
        my @parts_b = split /\./, $bbb;
        for (my $i = 0; $i < (@parts_a > @parts_b ? @parts_a : @parts_b); $i++) {
          last unless $i < @parts_a and $i < @parts_b;
          my $number_a = $parts_a[$i];
          my $number_b = $parts_b[$i];
          if ($number_a =~ /^0/ and $number_b !~ /^0/) {
            $number_b .= '0' x ($max_length - length $number_b);
          } elsif ($number_b =~ /^0/ and $number_a !~ /^0/) {
            $number_a .= '0' x ($max_length - length $number_a);
          } else {
            $number_a = sprintf '%0'.$max_length.'d', $number_a;
            $number_b = sprintf '%0'.$max_length.'d', $number_b;
          }
          $parts_a[$i] = $number_a;
          $parts_b[$i] = $number_b;
        }
        $aaa = join '.', @parts_a;
        $bbb = join '.', @parts_b;
      }
      for my $i ($aaa, $bbb) {
        my @parts = split /\./, $i;
        for my $number (@parts) {
          $number = sprintf '%0'.$max_length.'d', $number;
        }
        $i = join '.', @parts;
      }
      my $dots_a = scalar (my @dots_a = $aaa =~ /\./g);
      my $dots_b = scalar (my @dots_b = $bbb =~ /\./g);
      if ($dots_a > $dots_b) {
        my $rest = $dots_a - $dots_b;
        for my $i (1..$rest) {
          $bbb .= '.0';
        }
      } elsif ($dots_b > $dots_a) {
        my $rest = $dots_b - $dots_a;
        for my $i (1..$rest) {
          $aaa .= '.0';
        }
      }
      $result = version->parse($aaa) <=> version->parse($bbb);
      if (!$result) {
        $result = length($oa) <=> length($ob);
      }
      last if $result;
    } elsif (is_number($aaa) and is_number($bbb)) {
      $result = $aaa <=> $bbb;
      last if $result
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

sub _is_numeric {
  my $v = shift;
  return if is_number $v;
  return 1 if $v =~ /^\d+(\.\d+)*$/;
  0;
}