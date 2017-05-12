use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Net::SSH2::Expect',
   VERSION_FROM => 'lib/Net/SSH2/Expect.pm',
   PREREQ_PM => {'Net::SSH2' => '0.44'},
   LICENSE => 'perl'
);

