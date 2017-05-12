# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use strict;
use warnings FATAL => 'all';

use 5.006;

use ExtUtils::MakeMaker 6.59;

WriteMakefile(
    NAME               => 'MooX::Role::Reconstruct',
    AUTHOR             => 'Jim Bacon <jim@nortx.com>',
    VERSION_FROM       => 'lib/MooX/Role/Reconstruct.pm',
    ABSTRACT_FROM      => 'lib/MooX/Role/Reconstruct.pm',
    LICENSE            => 'Perl',
    PL_FILES           => {},    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.59,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        # NOTE the use of quotes around non-numeric strings!
        #'ABC'              => 0,
        #'Foo::Bar::Module' => 5.004001,
        #'Foo::Bar::Module' => '5.4_1',
        #'Foo::Bar::Module' => '5.4.1',
        #'Foo::Bar::Module' => 'v5.4_1',
        #'Foo::Bar::Module' => 'v5.4.1',
        'perl'       => 5.006,
        'Sub::Quote' => 0,
        'Sub::Defer' => 0,
        'Role::Tiny' => 0,
    },
    test => { TESTS => "t/*.t t/*/*.t" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MooX-Role-Reconstruct-*' },
);
