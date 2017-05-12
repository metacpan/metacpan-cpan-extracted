use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Proc::Wait3',
    'LICENSE'           => 'perl',
    'VERSION_FROM'	=> 'Wait3.pm', # finds $VERSION
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Wait3.pm', # retrieve abstract from module
       AUTHOR     => 'C. Tilmes <ctilmes@cpan.org>') : ()),
);
