use Test::More;
use strict;
use FindBin;
use File::Spec;
use PPM::Make::RepositorySummary;

for my $dir(qw(PPMPackages ppms)) {
  my $rep = File::Spec->catdir($FindBin::Bin, $dir);
  ok (-d $rep);
  my $obj = PPM::Make::RepositorySummary->new(rep => $rep);
  is(ref($obj), 'PPM::Make::RepositorySummary');
  $obj->summary();

  for my $file(qw(package.lst summary.ppm searchsummary.ppm package.xml)) {
    my $received = File::Spec->catfile($rep, $file);
    my $expected = File::Spec->catfile($rep, 'cmp_' . $file);
    my ($expected_received, $expected_expected) =
      expected_sizes($expected, $received);
    is($expected_received, $expected_expected);
    unlink($received);
  }
}

done_testing;

# compares the sizes of two files, disregarding
# possible \r differences between them,
# useful especially when working with cvs across
# unix and windows
sub expected_sizes {
  my ($f1, $f2) = @_;
  my ($f1_is_dosish, $f1_lines) = is_dosish($f1);
  my ($f2_is_dosish, $f2_lines) = is_dosish($f2);
  my $f1_size = -s $f1;
  my $f2_size = -s $f2;
  if ($f1_is_dosish and $f2_is_dosish) {
    return ($f1_size, $f2_size);
  }
  elsif ($f1_is_dosish and not $f2_is_dosish) {
    return ($f1_size-$f1_lines, $f2_size);
  }
  elsif (not $f1_is_dosish and $f2_is_dosish) {
    return ($f1_size, $f2_size-$f2_lines);
  }
  else {
    return ($f1_size, $f2_size);
  }
}

# returns ($is_dosish, $number_of_lines) in a file,
# where $is_dosish is true if the file has \r
sub is_dosish {
  my $file = shift;
  my ($is_dosish, $lines);
  open(my $fh, '<', $file) or die qq{Cannot open $file: $!};
  binmode($fh);
  while (my $line = <$fh>) {
    unless ($is_dosish) {
      $is_dosish++ if ($line =~ /\r/);
    }
    $lines++;
  }
  close $fh;
  return ($is_dosish, $lines);
}
