use Test::Most 0.25;

use Path::Class::Tiny;

use Path::Tiny ();


my $dir = path(Path::Tiny->tempdir)->child('sub');
$dir->mkpath or die("can't make dir: $dir");
chdir $dir or die("can't change to dir: $dir");
note "pwd is ", Path::Tiny->cwd;

my $a = $dir->child('a');
my $b = $dir->child('b');
my $c = $dir->child('c');
my $ldir = $dir->child('..', 'ln');

$a->touch;
$b->touch;
symlink $a, $c;
symlink $dir, $ldir;
my $rel  = path('a');
my $rel2 = path('..', 'sub', 'a');

# different files are different
ok !$a->ef( $b ), "file A not -ef file B (as Path::Class::Tiny)";
ok !$a->ef("$b"), "file A not -ef file B (as string)";
# same file is the same
ok $a->ef( $a ), "file A -ef file A (as Path::Class::Tiny)";
ok $a->ef("$a"), "file A -ef file A (as string)";
# absolute equals relative
ok $a->ef( $rel ), "file A -ef ./A (as Path::Class::Tiny)";
ok $a->ef("$rel"), "file A -ef ./A (as string)";
# relative equals different relative
ok $rel->ef( $rel2 ), "./A -ef ../S/A (as Path::Class::Tiny)";
ok $rel->ef("$rel2"), "./A -ef ../S/A (as string)";
# file is the same as its symlink
ok $a->ef( $c ), "file A -ef link C (as Path::Class::Tiny)";
ok $a->ef("$c"), "file A -ef link C (as string)";
# relative file equals absolute symlink
ok $rel->ef( $c ), "./A -ef link C (as Path::Class::Tiny)";
ok $rel->ef("$c"), "./A -ef link C (as string)";
# file is the same as itself when accessed via symlinked dir
ok $ldir->child('a')->ef( $a ), "alt A -ef file A (as Path::Class::Tiny)";
ok $ldir->child('a')->ef("$a"), "alt A -ef file A (string)";
# file is the same as symlink when accessed via symlinked dir
ok $ldir->child('a')->ef( $c ), "alt A -ef link C (as Path::Class::Tiny)";
ok $ldir->child('a')->ef("$c"), "alt A -ef link C (string)";


done_testing;
