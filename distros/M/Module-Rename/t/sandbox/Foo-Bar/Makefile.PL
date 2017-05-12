######################################################################
# Makefile.PL for Foo::Bar
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Foo::Bar',
    'VERSION_FROM' => 'lib/Foo/Bar.pm', # finds $VERSION
    'PREREQ_PM'    => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Foo/Bar.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
