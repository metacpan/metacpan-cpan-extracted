use ExtUtils::MakeMaker;

WriteMakefile(
        'NAME' => 'PDL::LinearAlgebra::Special',
        'VERSION_FROM' => 'Special.pm',
        'clean' => { FILES => '*~' },
       );
__END__

