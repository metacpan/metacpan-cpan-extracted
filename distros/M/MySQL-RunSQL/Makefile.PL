use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MySQL::RunSQL',
    VERSION_FROM      => 'lib/MySQL/RunSQL.pm', # finds $VERSION
    PREREQ_PM         => {
                            Modern::Perl => 1.20120521,
                            DBI    =>   1.617,
                            Params::Validate => 1.06,
                            Excel::Writer::XLSX =>  0.50
                        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MySQL/RunSQL.pm', # retrieve abstract from module
       AUTHOR         => 'Melissa A. VandenBrink <geeklady@gmail.com>') : (GEEKLADY)),
);
