# Check the functioning related to subdirectories

use warnings;
use strict;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Parse::Gitignore;
use FindBin '$Bin';
my $dir = "$Bin/subd";
my $pg = Parse::Gitignore->new ("$dir/.gitignore");
$pg->read_gitignore ("$dir/subsubd");
ok ($pg->ignored ("$dir/test1"), "$dir/test1 ignored");
ok ($pg->ignored ("$dir/subsubd/test2"), "$dir/subsubd/test2 ignored");
done_testing ();
