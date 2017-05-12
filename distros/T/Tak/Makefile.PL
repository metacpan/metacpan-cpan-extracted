use strict;
use warnings FATAL => 'all';
use 5.008001;
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'Tak',
  VERSION_FROM => 'lib/Tak.pm',
  PREREQ_PM => {
    'Moo' => '0.009012',
    'Net::OpenSSH' => '0.52',
    'Log::Contextual' => '0.004',
    'JSON::PP' => '2.27104',
    'Capture::Tiny' => '0.11',
    'warnings::illegalproto' => 0,
    'Data::Dumper::Concise' => '2.020',
    'Eval::WithLexicals' => '1.001000',
    'IPC::System::Simple' => '1.21',
    'Config::Settings' => '0.02',
    'IO::All' => '0.44',
  },
  LICENSE => 'perl',
  EXE_FILES => [ 'bin/tak', 'bin/tak-stdio-node' ],
  META_MERGE => {
    'no_index' => { file => [ 'lib/Tak/STDIONode.pm' ] },
     resources => {
         license     => 'http://dev.perl.org/licenses/',
         repository  => 'git://git.shadowcat.co.uk/scpubgit/Tak.git',
     },
  }
);
