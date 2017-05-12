use ExtUtils::MakeMaker;
WriteMakefile
  (
   NO_META => 1,
   NAME => "Schedule::Cron",
   VERSION_FROM => "lib/Schedule/Cron.pm",
   ($] >= 5.005
    ? (ABSTRACT   => 'Cron-like scheduler for Perl subroutines',
       AUTHOR     => 'Roland Huss (roland@cpan.org)',
       META_MERGE  => {
                       resources  => {
                                      repository => 'https://github.com/rhuss/schedule-cron',
                                     },
                      },
       PL_FILES => {})
    : ()),
   ($ExtUtils::MakeMaker::VERSION >= 6.3002 ?
    ('LICENSE'		=> 'perl', ) : ()),
   PREREQ_PM => { "Time::ParseDate" => '2011.0505',"Data::Dumper" => 0},
   'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'}
  );
