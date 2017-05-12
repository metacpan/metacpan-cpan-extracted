use strict;
use warnings;
use Test::More;
use FindBin;
use Parse::PMFile;

eval "use version::vpp; 1" or plan skip_all => "requires version::vpp";

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
  my $v3 = version::vpp->parse('0.03');
  my $v4 = version::vpp->parse('0.04');
  ok $v3 < $v4, "FORK $fork: 0.04 should be greater than 0.03";
  ok $v3 lt $v4, "FORK $fork: 0.04 should be greater than 0.03";
  ok (($v3 ? 1 : 0), "FORK $fork: bool");
  note "v3: $v3 v4: $v4";
}
