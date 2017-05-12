use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

my $pmfile = "$tmpdir/Test.pm";
{
  open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
  print $fh "package " . "Parse::PMFile::Test;\n";
  print $fh 'our $VERSION = qv("1.51_01");',"\n";
  close $fh;
}

for (0..1) {
  no warnings 'once';
  local $Parse::PMFile::FORK = $_;
  my $parser = Parse::PMFile->new(undef, {ALLOW_DEV_VERSION => 1});

  {
    my $expected =
      (version->VERSION > 0.9912) ? "1.5101000" : "1.051_001";

    my @warnings;
    local $SIG{__WARN__} = sub {push @warnings, @_};
    my $info = $parser->parse($pmfile);
    is $info->{'Parse::PMFile::Test'}{version} => $expected;
    note explain $info;
    ok !@warnings;
    note join "\n", @warnings;
  }

}

done_testing;
