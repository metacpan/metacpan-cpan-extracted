use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'PL_FILES' => {},
               'NAME' => 'Process::Results',
               'VERSION_FROM' => 'lib/Process/Results.pm',
               'ABSTRACT' => 'Process::Results - standardized structure for returning results of a process',
               'PREREQ_PM' => {
                                'Test::Most' => '0.34',
                                'B' => '1.42_02',
                                'JSON::Tiny' => '0.50'
                              },
               'EXE_FILES' => [],
               'LICENSE' => 'perl',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>'
             };


WriteMakefile(%$make_args);
