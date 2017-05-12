use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'My::Object',
    AUTHOR => 'Christoph Gärtner <cygx@cpan.org>',
    LICENSE => 'open_source',
    VERSION_FROM => 'lib/My/Object.pm',
    ABSTRACT_FROM => 'lib/My/Object.pm',
    PREREQ_PM => { 'Test::More' => 0 },
);
