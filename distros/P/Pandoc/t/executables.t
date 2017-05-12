use strict;
use Test::More;
use File::Temp;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;
plan skip_all => 'these tests are for release candidate testing'
    unless $ENV{RELEASE_TESTING};

my $dir = File::Temp->newdir;

ok symlink(pandoc->bin, "$dir/foo"), 'create symlink';
new_ok 'Pandoc', [ "$dir/foo" ], 'executable not named "pandoc"';

done_testing;
