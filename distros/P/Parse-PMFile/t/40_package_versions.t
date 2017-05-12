use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

test('package '.'Parse::PMFile::Test', <<'TEST');
{
  $Parse::PMFile::Test::VERSION = "0.01";
}
TEST

test('package '.'Parse::PMFile::Test', <<'TEST');
{
  $VERSION = "0.01";
}
TEST

test('package '.'Parse::PMFile::Test {', <<'TEST');
  $Parse::PMFile::Test::VERSION = "0.01";
};
TEST

test('package '.'Parse::PMFile::Test {', <<'TEST');
  $VERSION = "0.01";
};
TEST

test('package '.'Parse::PMFile::Test 0.01 {', <<'TEST');
};
TEST

sub test {
  my @lines = @_;

  my $pmfile = "$tmpdir/Test.pm";

  open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
  print $fh join "\n", @lines, "";
  close $fh;

  for (0..1) {
    no warnings 'once';
    local $Parse::PMFile::FORK = $_;
    my $parser = Parse::PMFile->new;
    my $info = $parser->parse($pmfile);

    is $info->{'Parse::PMFile::Test'}{version} => '0.01';
    # note explain $info;
  }
}

done_testing;

