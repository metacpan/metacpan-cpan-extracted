use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Query::Abstract',
    VERSION_FROM  => 'lib/Query/Abstract.pm',
    ABSTRACT_FROM => 'lib/Query/Abstract.pm',
    AUTHOR        => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM     => { 
        'Class::Load' => 0, 
    },
    MIN_PERL_VERSION => 5.010,
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/koorchik/Query-Abstract',
            bugtracker => 'http://github.com/koorchik/Query-Abstract/issues',
            license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Query-Abstract-*' },
    test          => { TESTS => 't/*.t' },
);