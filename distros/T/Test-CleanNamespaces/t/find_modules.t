use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use File::pushd 'pushd';
use Test::CleanNamespaces;

{
    my $dir = pushd 't/corpus/blib_and_lib';

    cmp_deeply(
        [ Test::CleanNamespaces::find_modules() ],
        bag(
            'Foo::Bar',
        ),
        'correctly found modules in blib',
    );
}

{
    my $dir = pushd 't/corpus/just_lib';

    cmp_deeply(
        [ Test::CleanNamespaces::find_modules() ],
        bag(
            'Gamma::Delta',
        ),
        'correctly found modules in lib',
    );
}

done_testing;
