use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Template::Iterator::XS',
    'VERSION_FROM'	=> 'XS.pm',
    'PREREQ_PM'		=> {'Template' => 2.00}, 
);
