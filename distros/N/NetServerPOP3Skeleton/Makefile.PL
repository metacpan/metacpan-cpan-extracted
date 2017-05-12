use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Tk::Carp',
    'VERSION_FROM'  => 'lib/Tk/Carp.pm', # finds $VERSION
    #'ABSTRACT_FROM' => 'lib/Tk/Carp.pm', # retrieve abstract from module
    'AUTHOR'        => 'Cory Johns <johnsca@cpan.org>',
    'PREREQ_PM'     => {
      'Tk'   => 0,
      'Carp' => 0,
    },
);
