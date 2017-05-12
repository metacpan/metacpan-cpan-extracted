use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME                => 'QMake::Project',
    AUTHOR              => q{Rohan McGovern <rohan@mcgovern.id.au>},
    VERSION_FROM        => 'lib/QMake/Project.pm',
    ABSTRACT_FROM       => 'lib/QMake/Project.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'lgpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp' => 0,
        'File::Basename' => 0,
        'File::Spec::Functions' => 0,
        'File::Temp' => 0,
        'File::Which' => 0,
        'File::chdir' => 0,
        'IO::File' => 0,
        'List::MoreUtils' => 0,
        'ReleaseAction' => 0,
        'Scalar::Defer' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
        'Test::Warn' => 0,
        'Text::ParseWords' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'QMake-Project-*' },
);
