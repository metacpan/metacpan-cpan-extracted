use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Sys::Apm',
    'VERSION_FROM'	=> 'Apm.pm',
    ($] >= 5.005 ?   
       (AUTHOR     => 'Raoul Zwart <rlzwart@cpan.org>') : ()),
);
