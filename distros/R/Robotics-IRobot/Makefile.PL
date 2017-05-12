use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Robotics::IRobot',
    AUTHOR              => q{Michael Ratliff <email@michaelratliff.com>},
    VERSION_FROM        => 'lib/Robotics/IRobot.pm',
    ABSTRACT_FROM       => 'lib/Robotics/IRobot.pm',
    ((split(/_/,$ExtUtils::MakeMaker::VERSION))[0] >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Time::HiRes' => 0,
	'Device::SerialPort' => 0,
	'YAML::Tiny' => 0,
	'POSIX' => 0,
	'Math::Trig' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Robotics-IRobot-*' },
);
