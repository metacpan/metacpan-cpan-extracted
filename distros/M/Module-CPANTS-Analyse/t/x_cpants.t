use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Module::CPANTS::TestAnalyse;

test_distribution {
  my ($mca, $dir) = @_;
  write_metayml("$dir/META.yml");
  write_pmfile("$dir/Test.pm");

  my $res = $mca->run;

  ok !$res->{kwalitee}{use_strict}, "use_strict fails correctly";
  ok !$res->{kwalitee}{has_tests}, "has_tests fails correctly";
};

test_distribution {
  my ($mca, $dir) = @_;

  write_pmfile("$dir/Test.pm");
  write_metayml("$dir/META.yml", {
    x_cpants => {ignore => {
      use_strict => 'for some reason',
    }}
  });

  my $res = $mca->run;
  ok $res->{kwalitee}{use_strict}, "use_strict is ignored (and treated as pass)";
  ok $res->{error}{use_strict} && $res->{error}{use_strict} =~ /Module::CPANTS::Analyse::Test/ && $res->{error}{use_strict} =~ /ignored/, "error is not removed and marked as 'ignored'";
  ok !$res->{kwalitee}{has_tests}, "has_tests fails correctly";
};

test_distribution {
  my ($mca, $dir) = @_;

  write_pmfile("$dir/Test.pm");
  write_metayml("$dir/META.yml", {
    x_cpants => {ignore => {
      use_strict => 'for some reason',
      has_tests => 'because I am so lazy',
    }}
  });

  my $res = $mca->run;
  ok $res->{kwalitee}{use_strict}, "use_strict is ignored (and treated as pass)";
  ok $res->{error}{use_strict} && $res->{error}{use_strict} =~ /Module::CPANTS::Analyse::Test/ && $res->{error}{use_strict} =~ /ignored/, "error is not removed and marked as 'ignored'";
  ok !$res->{kwalitee}{has_tests}, "has_tests fails correctly regardless of the x_cpants";
};

done_testing;
