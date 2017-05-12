use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Task::Pluggable',
    AUTHOR              => 'Masafumi Yoshida <masafumi.yoshida820@gmail.com>',
    VERSION_FROM        => 'lib/Task/Pluggable.pm',
    ABSTRACT_FROM       => 'lib/Task/Pluggable.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Class::Accessor' => 0,
        'Class::Data::Inheritable' => 0,
        'Module::Pluggable::Fast' => 0,
        'Term::ANSIColor' => 0,
        'Test::More' => 0,
        'YAML' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Task-Pluggable-*' },
);
