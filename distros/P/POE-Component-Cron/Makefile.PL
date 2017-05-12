use 5.008003;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'POE::Component::Cron',
    VERSION_FROM => 'lib/POE/Component/Cron.pm',    # finds $VERSION
    PREREQ_PM    => {
        'POE'                      => 0,
        'POE::Component::Schedule' => '0',
        'DateTime::Event::Cron'    => '0',
        'DateTime::Event::Random'  => '0',
        'DateTime'                 => '0',
    },                                              # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/POE/Component/Cron.pm',    # retrieve abstract from module
            AUTHOR => 'Chris Fedde <cfedde@littleton.co.us>'
          )
        : ()
    ),
);
