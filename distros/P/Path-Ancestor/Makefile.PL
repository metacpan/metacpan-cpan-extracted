######################################################################
# Makefile.PL for Path::Ancestor
# 2008, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Path::Ancestor',
    'VERSION_FROM' => 'Ancestor.pm', # finds $VERSION
    'PREREQ_PM'    => {
        'List::Util' => 1.18,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Ancestor.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
