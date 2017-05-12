use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'SAVI',
    'VERSION_FROM' => 'SAVI.pm',
    'LIBS'	=> ['-L/opt/local/lib -R/opt/local/lib -lsavi'],
    'DEFINE'	=> '',
    'INC'	=> '-I.',
);
