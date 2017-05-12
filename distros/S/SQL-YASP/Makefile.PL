use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'SQL::YASP',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'SQL::YASP - SQL parser and evaluater',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/SQL/YASP.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'Tie::IxHash' => 0
                              }
             };


WriteMakefile(%$make_args);
