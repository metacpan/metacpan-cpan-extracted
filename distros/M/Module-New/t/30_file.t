use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Module::New;

subtest simple => sub {
  Module::New->setup('Module::New::ForTest');

  my %files = Module::New::ForTest::File::Simple->render;

  my $num_of_files = keys %files;
  ok $num_of_files == 1, 'one file';
  ok $files{Simple} =~ /today is \d{4}\/\d{2}\/\d{2}\./, 'has Simple file content';
};

done_testing;

BEGIN {
  package #
    Module::New::ForTest::File::Simple;
  use Module::New::File;

  file 'Simple' => content { return <<'EOT';
today is <%= $c->date->ymd('/') %>.
EOT
  };
}
