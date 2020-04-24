package Org::FRDCSA::AIE::Method::SimpleLCS;

use Algorithm::Diff qw(LCS);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw (AIE);

sub AIE {
  my %args = @_;
  my $entries = $args{Entries};
  my $size = scalar @$entries;
  my @intermediate = split //, $entries->[0];
  foreach my $i (0 .. ($size - 2)) {
    @intermediate = LCS(\@intermediate,[split //, $entries->[$i + 1]]);
  }
  my $regex = join("(.*)",@intermediate);
  print $regex."\n";
  foreach my $entry (@$entries) {
    my @results;
    my @matches = $entry =~ /$regex/;
    foreach my $match (@matches) {
      if ($match ne "") {
	push @results, $match;
      }
    }
    push @all,\@results;
  }
  return \@all;
}

1;
