use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

test('undef', 'class '.'Parse::PMFile::Test;');

test('undef', 'class '.'Parse::PMFile::Test { }');

test('undef', 'class '.'Parse::PMFile::Test :isa(Foo);');

test('undef', 'class '.'Parse::PMFile::Test :isa(Foo) { }');

test('0.01', 'class '.'Parse::PMFile::Test', <<'TEST');
{
  $Parse::PMFile::Test::VERSION = "0.01";
}
TEST

test('0.01', 'class '.'Parse::PMFile::Test', <<'TEST');
{
  $VERSION = "0.01";
}
TEST

test('0.01', 'class '.'Parse::PMFile::Test {', <<'TEST');
  $Parse::PMFile::Test::VERSION = "0.01";
};
TEST

test('0.01', 'class '.'Parse::PMFile::Test {', <<'TEST');
  $VERSION = "0.01";
};
TEST

test('0.01', 'class '.'Parse::PMFile::Test 0.01 {', <<'TEST');
};
TEST

test('0.01', 'class '.'Parse::PMFile::Test 0.01 :isa(Foo) :does(Bar) {', <<'TEST');
};
TEST

sub test {
  my ($version, @lines) = @_;

  my $pmfile = "$tmpdir/Test.pm";

  open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
  print $fh join "\n", 'use experimental qw(class);', @lines, "";
  close $fh;

  for (0..1) {
    no warnings 'once';
    local $Parse::PMFile::FORK = $_;
    my $parser = Parse::PMFile->new;
    my $info = $parser->parse($pmfile);

    is( $info->{'Parse::PMFile::Test'}{version} => $version )
        or diag join("\n", @lines);
    is( $parser->{VERSION} => $version )
        or diag 'VERSION ' . join("\n", @lines);
    # note explain $info;
  }
}

done_testing;

