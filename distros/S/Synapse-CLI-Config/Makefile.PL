use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Synapse::CLI::Config',
    VERSION_FROM => './lib/Synapse/CLI/Config.pm',
    PREREQ_PM    => {
        'YAML::XS' => 0.38,
        'Time::HiRes' => 1.9719,
        'File::Touch' => 0.08,
        'File::Copy' => 2.18,
    }
);
