use Perlmazing qw(is_number);

sub main ($) {
  return unless is_number $_[0];
  return unless int($_[0]) == $_[0];
  1;
}

1;
