use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'SWISH::API::More',
    VERSION_FROM      => 'lib/SWISH/API/More.pm', # finds $VERSION
    PREREQ_PM         => {
                      #'SWISH::API' => '0.04',  # we test for this in t/ but since it isn't on cpan we don't require it.
                      'Data::Dump' => '1.06',
                      'Class::Accessor::Fast' => '0.22',
                      'Class::ISA' => 0.01,
                      'Class::Inspector' => 0.01

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISH/API/More.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <karman@cpan.org>') : ()),
);
