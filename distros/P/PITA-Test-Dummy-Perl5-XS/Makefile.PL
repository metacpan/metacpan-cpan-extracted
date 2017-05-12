use ExtUtils::MakeMaker;

my %opts = 
  (
   NAME => 'PITA::Test::Dummy::Perl5::XS',
   VERSION_FROM => 'XS.pm',
   OBJECT => 'XS.o',
  );
if ($ExtUtils::MakeMaker::VERSION > 6.06) {
  $opts{AUTHOR} = 'Tony Cook <tony@develop-help.com>';
  $opts{ABSTRACT} = 'Test Dummy';
}

WriteMakefile(%opts);


