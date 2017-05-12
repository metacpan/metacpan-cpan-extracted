use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'PREREQ_PM' => {
                                'Test::Toolbox' => '0.2',
                                'Number::Misc' => '1.2'
                              },
               'LICENSE' => 'perl',
               'ABSTRACT' => 'String::Util -- String processing utilities',
               'NAME' => 'String::Util',
               'VERSION_FROM' => 'lib/String/Util.pm',
               'PL_FILES' => {},
               'EXE_FILES' => []
             };


WriteMakefile(%$make_args);
