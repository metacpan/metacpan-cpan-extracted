use Test::More;
use File::Path;

BEGIN {
    @INC = grep { not /[\\\/]inc$/ } @INC;
    eval 'require Module::Install; 1' or
        plan skip_all => 'This test requires Module::Install';

    File::Path::rmtree("t/lib/Foo/Bar");
    my $module_file = "t/lib/Foo/Mousse.pm";
    unlink($module_file) if -e $module_file;
    die if -e $module_file;
    system("(cd t; $^X Makefile.PL)");
    plan tests => 2;
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
File::Path::rmtree("t/inc");
File::Path::rmtree("t/lib/Foo/Mousse.pm");
