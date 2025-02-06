use Perlmazing qw(croak is_number);
sub main ($) {
  my $value = shift || 0;
  unless (is_number $value) {
    croak "Use of non-numeric value in decimals()";
  }
  my $int = int $value;
  return $value - $int;
}

1;
