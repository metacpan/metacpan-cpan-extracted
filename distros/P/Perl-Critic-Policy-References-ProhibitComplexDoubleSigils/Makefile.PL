use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Perl::Critic::Policy::References::ProhibitComplexDoubleSigils',
    VERSION_FROM      => 'lib/Perl/Critic/Policy/References/ProhibitComplexDoubleSigils.pm',
    PREREQ_PM         => {
        'Perl::Critic' => 0,
    },
    ABSTRACT_FROM     => 'lib/Perl/Critic/Policy/References/ProhibitComplexDoubleSigils.pm',
    AUTHOR            => 'Tomasz Konojacki <me@xenu.tk>',
    LICENSE           => 'perl',
    META_MERGE    => {
         resources => {
             repository => 'http://code.xenu.tk/repos.cgi/prohibit-complex-double-sigils'
         }
    },
);
