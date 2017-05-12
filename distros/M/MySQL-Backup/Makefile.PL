
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MySQL::Backup',
    VERSION_FROM      => 'lib/MySQL/Backup.pm',
    PREREQ_PM         => {'DBI' => 0,
                          'DBD::mysql' => 0},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/MySQL/Backup.pm',
       AUTHOR         => 'Dmitry Nikolayev <dmitry@cpan.org>') : ()),
);
