# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestPW;

foreach my $eg ( ['t/eg'], ['t/eg2', 'MyExtraWord1 exword2 sw3'] ){
  my ($dir, $words) = @$eg;
  my $input = weaver_input();
  my $weaver = Pod::Weaver->new_from_config({ root => $dir });
  test_basic($weaver, $input, $words);
}

foreach my $dir ( glob("t/ini-*") ){
  next unless -d $dir;
  my $input = weaver_input($dir);
  my $expected = $input->{expected};
  my $weaver = Pod::Weaver->new_from_config({ root => $dir });
  my $woven = $weaver->weave_document($input);

  compare_pod_ok(
    $woven->as_pod_string,
    $expected,
    "exactly the pod string we wanted after weaving in $dir!",
  );
}

done_testing;
