use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		    => 'Pod::Stripper',
    'VERSION_FROM'	=> 'Stripper.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Test' => 1.15,
                         'Pod::Parser' => 1.13,
                       ,},
    'ABSTRACT_FROM' => 'Stripper.pm',
    'AUTHOR'        => 'D.H. aka crazyinsomniac|at|yahoo.com',
    'DISTNAME'      => 'Pod-Stripper',
    'EXE_FILES'     => ['podstrip'],
,);
