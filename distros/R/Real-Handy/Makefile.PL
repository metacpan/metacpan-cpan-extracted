use 5.008001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Real::Handy',
    VERSION_FROM      => 'lib/Real/Handy.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
      (ABSTRACT_FROM  => 'lib/Real/Handy.pm', # retrieve abstract from module
       AUTHOR         => 'Anatoliy Grishayev<grian@cpan.org>'),
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
