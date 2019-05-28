use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'SQL::Shell',
    VERSION_FROM     => 'lib/SQL/Shell.pm',
    ABSTRACT_FROM    => 'lib/SQL/Shell.pm',
    AUTHOR           => ['British Broadcasting Corporation','Miguel Gualdron'],
    LICENSE          => 'gpl_2',
    MIN_PERL_VERSION => '5.008004',
    EXE_FILES        => ['bin/sqlsh'],
    PREREQ_PM        => {
      DBI => 0,
      URI::Escape => 0,
      Log::Trace => 0,
      Test::Assertions => 0,
      Test::Assertions::TestScript => 0,
      IO::CaptureOutput => 0,
      IO::Scalar => 0,
      CGI => 0,
      Locale::Recode => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mgualdron/SQL-Shell.git',
                web  => 'https://github.com/mgualdron/SQL-Shell',
            },
        }})
     : ()
    ),
);
