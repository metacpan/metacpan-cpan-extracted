use Test::Most 0.25;

use Path::Class::Tiny;

use Path::Tiny ();


my $CLASS = 'Path::Class::Tiny';

my $dir = path(Path::Tiny->tempdir)->child('sub');
$dir->mkpath or die("can't make dir: $dir");


isa_ok $dir, $CLASS, "base object [sanity check]";
isa_ok $dir->parent, $CLASS, "obj returned by parent()";
isa_ok $dir->dir, $CLASS, "obj returned by dir()";
isa_ok $dir->child('foo'), $CLASS, "obj returned by child()";
isa_ok $dir->file('foo'), $CLASS, "obj returned by file()";
isa_ok $dir->subdir('foo'), $CLASS, "obj returned by subdir()";
isa_ok $dir->realpath, $CLASS, "obj returned by realpath()";


done_testing;
