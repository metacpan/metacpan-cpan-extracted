use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Simple::Filter::Macro',
    VERSION_FROM      => 'lib/Simple/Filter/Macro.pm', # Finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {'Filter::Simple::Compile' => '0.0.2',
                          'File::Basename' => '2.85'}, # e.g. 'Module::Name' => '1.1'
    ABSTRACT_FROM     => 'lib/Simple/Filter/Macro.pm', # Retrieve abstract from module
    AUTHOR            => 'Dr. Peter Netz <ztenretep@cpan.org>',
    LICENSE           => 'mit',
    # Value must be from legacy list of licenses here
    # http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
