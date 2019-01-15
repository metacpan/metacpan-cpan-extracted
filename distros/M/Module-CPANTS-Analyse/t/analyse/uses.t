use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Module::CPANTS::TestAnalyse;

for my $vstr (qw/v5.14 5.012/) {
  test_distribution {
    my ($mca, $dir) = @_;

    my $content = join "\n",
      'package '.'Module::CPANTS::Analyse::Test;',
      "use $vstr;",
      '1;',
    ;

    write_pmfile("$dir/lib/Module/CPANTS/Analyse/Test.pm", $content);

    my $stash = $mca->run;
    is $stash->{kwalitee}{use_strict} => 1;
    note explain $stash;
  };
}

done_testing;
