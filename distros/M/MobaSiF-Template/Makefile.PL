require 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MobaSiF::Template',
    PM            => +{
        'Template.pm' => '$(INST_LIBDIR)/Template.pm',
        'Compiler.pm' => '$(INST_LIBDIR)/Template/Compiler.pm',
    },
    VERSION_FROM  => 'Template.pm',
    PREREQ_PM     => +{},
    ABSTRACT_FROM => 'Template.pm',
    AUTHOR        => 'bobpp < bobpp@cpan.org >',
);

