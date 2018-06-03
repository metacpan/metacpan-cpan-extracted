use Test::Most 0.25;

use Path::Class::Tiny;

use Path::Tiny ();


my $dir = path(Path::Tiny->tempdir)->child('sub');
$dir->mkpath or die("can't make dir: $dir");
chdir $dir or die("can't change to dir: $dir");
note "pwd is ", Path::Tiny->cwd;

my $a = $dir->child('a');
my $b = $dir->child('b');

$a->touch;
$b->touch;
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

done_testing;
