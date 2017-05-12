use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sew::Color',
    VERSION_FROM      => 'lib/Sew/Color.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Perl Module for giving rgb values for colours of varous manufactures embroidery thread', 
       AUTHOR         => 'mark winder <markwin@cpan.org>') : ()),
);
