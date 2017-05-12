use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Number::Misc',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Number::Misc - handy utilities for numbers',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Number/Misc.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {}
             };


WriteMakefile(%$make_args);
