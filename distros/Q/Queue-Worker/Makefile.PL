

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Queue::Worker',
    VERSION_FROM => 'lib/Queue/Worker.pm', # finds \$VERSION
    AUTHOR       => 'A. U. Thor (a.u.thor@a.galaxy.far.far.away)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Test::TempDatabase' => '0.13'
		     , 'POSIX::RT::Semaphore' => ''
                    },
);
