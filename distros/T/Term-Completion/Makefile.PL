use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Term::Completion',
    VERSION_FROM => 'lib/Term/Completion.pm', # finds $VERSION
    PREREQ_PM    => { 'Term::ReadKey' => 2.30,
                      'IO::Handle' => 0 },
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    macro        => { TARFLAGS   => "--format=ustar -c -v -f", },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Completion.pm', # retrieve abstract from module
       AUTHOR         => 'Marek Rouchal <marekr@cpan.org>') : ()),
);
