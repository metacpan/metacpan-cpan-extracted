use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Statistics::Test::WilcoxonRankSum',
              AUTHOR              => 'Ingrid Falk <ingrid dot falk at loria dot fr>',
              VERSION_FROM        => 'lib/Statistics/Test/WilcoxonRankSum.pm',
              ABSTRACT_FROM       => 'lib/Statistics/Test/WilcoxonRankSum.pm',
              PL_FILES            => {},
              PREREQ_PM => {
                            'Test::More' => 0,
                            'version'    => 0,
                            'Carp'       => 0,
                            'Carp::Assert' => 0,
                            'Class::Std' => 0,
                            'Contextual::Return' => 0,
                            'List::Util' => 0,
                            'Set::Partition' => 0,
                            'Math::BigFloat' => 0,
                            'Math::Counting' => 0,
                            'Statistics::Distributions' => 0,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Statistics-Test-WilcoxonRankSum-*' },
             );
