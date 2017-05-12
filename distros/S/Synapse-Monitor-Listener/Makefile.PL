use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Synapse::Monitor::Listener',
    VERSION_FROM => './lib/Synapse/Monitor/Listener.pm',
    PREREQ_PM    => {
        'YAML::XS' => 0.38,
        'Time::HiRes' => 1.9719,
        'File::Touch' => 0.08,
	'Daemon::Generic' => 0.82,
	'Synapse::CLI::Config' => 0.1,
	'Synapse::Logger' => 0.1,
    },
    EXE_FILES => [ './scripts/synapse-monitor-listener-cli', './scripts/synapse-monitor-listener-service' ],
);
