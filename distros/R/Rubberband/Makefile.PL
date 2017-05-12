use 5.00005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Rubberband',
    VERSION_FROM      => 'lib/Rubberband.pm', # finds $VERSION
    PREREQ_PM         => {
        Maypole => 1.5,
        SQL::Translator => 0,
        Class::DBI::BaseDSN => 0,
        Class::DBI::DATA::Schema => 0,
        Module::Pluggable::Ordered => 1.2,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Rubberband.pm', # retrieve abstract from module
       AUTHOR         => 'Simon Cozens <simon@cpan.org>') : ()),
);
