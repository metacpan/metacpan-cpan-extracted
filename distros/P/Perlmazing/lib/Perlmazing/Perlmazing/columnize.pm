use Perlmazing qw(croak is_integer ceil);

sub main {
  my $columns = shift;
  croak 'Usage: columnize($total_columns, @array) - where $total_columns must be an integer greater than 0' unless is_integer $columns and $columns > 0;
  my @array = @_;
  return unless @array;
  my $group_size = ceil @array / $columns;
  my @result;
  for my $group (0..$group_size - 1) {
    for my $column (0..$columns - 1) {
      my $index = $column * $group_size + $group;
      if (exists $array[$index]) {
        push @{$result[$group]}, $array[$index];
      }
    }
  }
  @result;
}
