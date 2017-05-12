use ExtUtils::MakeMaker;

# $Id: Makefile.PL,v 1.4 2003/03/05 19:57:13 piers Exp $

WriteMakefile(
  AUTHOR    => 'P Kent (pause@selsyn.co.uk)',
  ABSTRACT  => 'Find out the times at which a cron entry would run, past or future, relative to any given time',
  NAME    => 'Schedule::Cron::Events',
  DISTNAME  => 'Schedule-Cron-Events',
  dist    => {
    COMPRESS  => 'gzip',
    SUFFIX    => '.gz',
  },
  VERSION_FROM  => 'lib/Schedule/Cron/Events.pm',
  PREREQ_PM => {
        Time::Local => 0,
        Set::Crontab => 0,
      },
  TEST_REQUIRES => {
      Test::Deep => 0,
      Test::More => 0,
      },
  EXE_FILES => [
    'cron_event_predict.plx',
  ],
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/kohts/Schedule--Cron--Events.git',
        web  => 'https://github.com/kohts/Schedule--Cron--Events',
      },
    },
  },
);

