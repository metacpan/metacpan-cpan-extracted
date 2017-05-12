
use ExtUtils::MakeMaker;

WriteMakefile(PREREQ_PM    => { Time::Local => 0 },
              NAME         => 'Schedule::Match',
              VERSION_FROM => 'Match.pm');
