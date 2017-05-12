use Test::More tests => 2;
use File::Path;

BEGIN {
    File::Path::rmtree("t/lib/Foo/Bar");
    my $module_file = "t/lib/Foo/Mousse.pm";
    unlink($module_file) if -e $module_file;
    die if -e $module_file;

    system(qq{(cd t; $^X -I../lib -MMousse::Maker -e make_mousse "Foo::Mousse" > lib/Foo/Mousse.pm)});
    File::Path::mkpath('t/lib/Foo/Bar/Baz');
    system(qq{(cd t; $^X -I../lib -MMousse::Maker -e make_mousse "Foo::Bar::Baz::Mousse" > lib/Foo/Bar/Baz/Mousse.pm)});
}

use lib 't/lib';

use Foo;

my $f = Foo->new(
    this => 'ok',
);

is $f->this, 'ok', 'Everything is OK';

my $f2 = Foo::Bar->new(
    that => 'ok',
);

is $f2->that, 'ok', 'Everything is OK';

File::Path::rmtree("t/lib/Foo/Bar");
File::Path::rmtree("t/lib/Foo/Mousse.pm");
