use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::ProcTerminator',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/POE/Component/ProcTerminator.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/ProcTerminator.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'POE'       => 0,
        'POE::Sugar::Attributes' => '0.02',
        'Proc::Terminator' => '0.03',
        'Class::Struct'     => 0,
        'Constant::Generate' => 0.16,
        'Moo'           => 0.009014
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-ProcTerminator-*' },
);
