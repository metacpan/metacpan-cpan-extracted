use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MooseX::Types::GTIN',
    VERSION_FROM      => 'lib/MooseX/Types/GTIN.pm', # finds $VERSION
    PREREQ_PM         => {
        Moose => 0,
        'MooseX::Types::Moose' => 0,
    },
    BUILD_REQUIRES => {
        'File::Find' => 0,
        'File::Spec' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
        'Class::Load' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MooseX/Types/GTIN.pm', # retrieve abstract from module
       AUTHOR         => 'Dave Lambley <davel@state51.co.uk>') : ()),
    META_MERGE => {
        resources => {
            repository => 'https://github.com/davel/MooseX-Types-GTIN',
            homepage   => 'http://search.cpan.org/~dlambley/MooseX-Types-GTIN/',
        },
    },

);
