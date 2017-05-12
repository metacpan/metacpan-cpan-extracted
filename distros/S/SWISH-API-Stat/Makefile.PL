use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'SWISH::API::Stat',
    VERSION_FROM      => 'lib/SWISH/API/Stat.pm', # finds $VERSION
    PREREQ_PM         => {
                        'SWISH::API' => 0.04,
                        'SWISH::API::More' => 0.03,
                        'Path::Class::File::Stat' => 0.02,


    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISH/API/Stat.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <karman@cpan.org>') : ()),
);
