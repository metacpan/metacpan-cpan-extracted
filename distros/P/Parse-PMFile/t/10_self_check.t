use strict;
use warnings;
use Test::More tests => 2;
use FindBin;
use Parse::PMFile;

for (0..1) {
  no warnings 'once';
  local $Parse::PMFile::FORK = $_;
  my $p = Parse::PMFile->new;
  my $pkg = $p->parse("$FindBin::Bin/../lib/Parse/PMFile.pm");

  is $pkg->{'Parse::PMFile'}{version} => $Parse::PMFile::VERSION, "version of Parse::PMFile matches \$Parse::PMFile::VERSION";
}
