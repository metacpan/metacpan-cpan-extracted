use strict;
use warnings;

use Test::More;

# Test::PerlTidy is a develop prerequisite, so it is only loaded when the test runs
plan skip_all => 'set AUTHOR_TESTING to enable this test' unless $ENV{AUTHOR_TESTING};
require Test::PerlTidy;

# Ask git for the files it would commit, so .gitignore is the single place to exclude from (scratch scripts, local/,
# blib/). Without a .git, e.g. in CI or an unpacked dist, fall back to walking the tree. Both cover the same files.
my $pathspec = q{'*.pl' '*.pm' '*.PL' '*.psgi' '*.t' ':(glob)**/cpanfile'};
my @files    = grep {-f} map { chomp; $_ } qx{git ls-files --cached --others --exclude-standard -- $pathspec 2>/dev/null};
@files = Test::PerlTidy::list_files( path => '.', exclude => [ 'blib/', 'local/', qr{^\.} ] ) if $? || !@files;

ok( Test::PerlTidy::is_file_tidy($_), "'$_'" ) for @files;
done_testing;
