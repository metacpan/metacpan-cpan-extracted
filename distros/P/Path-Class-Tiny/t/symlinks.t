use Test::Most 0.25;

my $can_symlink = eval { symlink("",""); 1 };
plan skip_all => "Missing symlink function ..." unless ($can_symlink);

use Path::Class::Tiny;
use Path::Tiny ();


# SETUP

my $dir = path(Path::Tiny->tempdir)->child('sub');
$dir->mkpath or die("can't make dir: $dir");
chdir $dir or die("can't change to dir: $dir");
note "pwd is ", Path::Tiny->cwd;

my $a = $dir->child('a');
my $b = $dir->child('b');
my $ldir = $dir->child('..', 'ln');

$a->touch;
symlink $a, $b;
symlink $dir, $ldir;
my $rel = path('a');


# test -ef stuff

# file is the same as its symlink
ok $a->ef( $b ), "file A -ef link B (as Path::Class::Tiny)";
ok $a->ef("$b"), "file A -ef link B (as string)";

# relative file equals absolute symlink
ok $rel->ef( $b ), "./A -ef link B (as Path::Class::Tiny)";
ok $rel->ef("$b"), "./A -ef link B (as string)";

# file is the same as itself when accessed via symlinked dir
ok $ldir->child('a')->ef( $a ), "alt A -ef file A (as Path::Class::Tiny)";
ok $ldir->child('a')->ef("$a"), "alt A -ef file A (string)";

# file is the same as symlink when accessed via symlinked dir
ok $ldir->child('a')->ef( $b ), "alt A -ef link B (as Path::Class::Tiny)";
ok $ldir->child('a')->ef("$b"), "alt A -ef link B (string)";


done_testing;
