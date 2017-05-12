###############
# MAKEFILE.PL #
###############

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Scalar::MultiValue' ,
    'VERSION_FROM'  => 'lib/Scalar/MultiValue.pm' ,
    'PREREQ_PM'     => {'Object::MultiType'  => 0.04} ,
    ($] >= 5.005 ?
      ( ABSTRACT_FROM => 'lib/Scalar/MultiValue.pm',
        AUTHOR        => 'Graciliano M. P. <gmpassos@cpan.org>'
       ) : ()
     ),
);

1;

