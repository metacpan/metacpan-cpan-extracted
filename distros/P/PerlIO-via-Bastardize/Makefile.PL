use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'PerlIO::via::Bastardize',
    'VERSION_FROM'	=> 'Bastardize.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Bastardize.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
