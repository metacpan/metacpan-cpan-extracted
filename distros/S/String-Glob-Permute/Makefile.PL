######################################################################
# Makefile.PL for String::Glob::Permute
# 2008, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'String::Glob::Permute',
    'VERSION_FROM' => 'Permute.pm', # finds $VERSION
    'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Permute.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
