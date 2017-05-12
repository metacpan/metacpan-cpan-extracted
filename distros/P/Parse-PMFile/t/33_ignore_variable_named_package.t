use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

my $pmfile = "$tmpdir/Test.pm";

open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
print $fh 'my $package = qq{Parse::PMFile::Test};', "\n";
print $fh '$package or', "\n";
print $fh 'die;', "\n";
print $fh 'our $VERSION = "0.01";',"\n"; # this should be ignored
close $fh;

for (0..1) {
  no warnings 'once';
  local $Parse::PMFile::FORK = $_;
  my $parser = Parse::PMFile->new;
  my $info = $parser->parse($pmfile);

  ok !$info->{'or'};
  note explain $info;
}

done_testing;

