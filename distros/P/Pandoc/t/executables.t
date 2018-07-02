use strict;
use Test::More;
use File::Temp;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;
plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};

my $dir = File::Temp->newdir;

isa_ok pandoc->symlink("$dir/foo"), 'Pandoc', 'symlink';
new_ok 'Pandoc', [ "$dir/foo" ], 'executable not named "pandoc"';

symlink "xxx", "$dir/pandoc"; # test overriding existing symlink
is pandoc->symlink("$dir")->bin, pandoc->bin, 'return Pandoc instance';
new_ok 'Pandoc', [ "$dir/pandoc" ], 'symlink in directory';

done_testing;
