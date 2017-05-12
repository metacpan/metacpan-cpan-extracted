use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Parse::Pyapp',
    'VERSION_FROM'	=> 'Pyapp.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Pyapp.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
