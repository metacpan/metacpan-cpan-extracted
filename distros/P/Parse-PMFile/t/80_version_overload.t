use strict;
use warnings;
use Test::More;
use FindBin;
use Parse::PMFile;

for my $fork (0..1) {
  test_version($fork);

  no warnings 'once';
  local $Parse::PMFile::FORK = $_;
  my $p = Parse::PMFile->new;
  my $pkg = $p->parse("$FindBin::Bin/../lib/Parse/PMFile.pm");

  is $pkg->{'Parse::PMFile'}{version} => $Parse::PMFile::VERSION, "version of Parse::PMFile matches \$Parse::PMFile::VERSION";

  test_version($fork);
}

done_testing;

sub test_version {
  my $fork = shift;

  # Does version.pm work correctly after Parse::PMFile is used?
  my $v1 = version->parse('0.01');
  my $v2 = version->parse('0.02');
  ok $v1 < $v2, "FORK $fork: 0.02 should be greater than 0.01";
  ok $v1 lt $v2, "FORK $fork: 0.02 should be greater than 0.01";
  ok (($v1 ? 1 : 0), "FORK $fork: bool");
  note "v1: $v1 v2: $v2";
}
