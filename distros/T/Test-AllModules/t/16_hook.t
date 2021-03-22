use strict;
use warnings;
use File::Spec;
use lib File::Spec->catfile('t','lib2');
use Test::AllModules;
use Test::More;

BEGIN {
    if ($^O eq 'MSWin32') {
        require Win32;
    }

    all_ok(
        search_path => 'MyApp2',
        use => 1,
        lib => [ File::Spec->catfile('t','lib2') ],
        before_hook => sub {
            my ($code, $class, $count) = @_;
            note "$count - $class";
            return;
        },
        after_hook  => sub {
            my ($ret, $code, $class, $count) = @_;
            note $ret ? "OK $class" : "Fail $class";
        },
    );
}
