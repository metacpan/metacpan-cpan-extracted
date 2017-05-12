use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Perl6::Contexts',
    'VERSION_FROM'	=> 'Contexts.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'B::Generate' => 1.06, }, # e.g., Module::Name => 1.1
    # 'ABSTRACT_FROM'     => 'Contexts.pm', # retrieve abstract from module - fails - no reason given
    'AUTHOR'            => 'Scott Walters SWALTERS <scott@slowass.net>',
);
