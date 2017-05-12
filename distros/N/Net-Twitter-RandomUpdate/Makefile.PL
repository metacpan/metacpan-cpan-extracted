use 5.008008;
use ExtUtils::MakeMaker;
                                               
WriteMakefile(
    NAME              => 'Net::Twitter::RandomUpdate',
    VERSION_FROM      => 'lib/Net/Twitter/RandomUpdate.pm',
    PREREQ_PM         => {
        'Net::Twitter' => 0,
    }, 
);

