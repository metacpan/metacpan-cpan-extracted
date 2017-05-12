use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'         => 'OS390::Stdio',
               'VERSION_FROM' => 'Stdio.pm',
               'MAN3PODS'     => {}, # pods will be built later by installman
               'DEFINE'       => '-D_EXT', # to pick up non_POSIX behavior
               'dist'         => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'}
             );
