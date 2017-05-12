use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Module::Check_Args',
    'AUTHOR'		=> 'Kevin Michael Vail <kevin@vailstar.com>',
    'VERSION_FROM'	=> 'Check_Args.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
);
