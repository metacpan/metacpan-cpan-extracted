use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Snail::CSV',
    VERSION_FROM      => 'lib/Snail/CSV.pm', # finds $VERSION
    PREREQ_PM         => {
Text::CSV_XS => 0.23,
IO::File => 1.13
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Snail/CSV.pm', # retrieve abstract from module
       AUTHOR         => 'Dmitriy Dontsov <mit@cpan.org>') : ()),
);
