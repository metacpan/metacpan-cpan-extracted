
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME              => 'Syntax::Kamelon',
   VERSION_FROM      => 'lib/Syntax/Kamelon.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
   LICENSE           => 'Perl',
   EXE_FILES => [
      'bin/kamelon',
      'bin/kamelon_analyze',
      'bin/kamelon_stepper',
   ],
   PREREQ_PM         => {
      'Data::Dumper' => 0,
      'Module::Load::Conditional' => 0,
      'Template' => 2.27,
      'Term::ANSIColor' => 4.00,
      'Test::More' => 1,
      'XML::TokeParser' => 0.05,
      'Time::HiRes' => 0,
   },
   ABSTRACT_FROM     => 'lib/Syntax/Kamelon.pod', # retrieve abstract from module
   (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
          resources => {
              repository => {
                 type => 'git',
                 url  => 'git://github.com/haje61/Kamelon.git',
                 web  => 'https://github.com/haje61/Kamelon',
              },
          }})
      : ()
    ),
);
