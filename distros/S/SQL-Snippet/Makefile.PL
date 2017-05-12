use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'          => 'SQL::Snippet',
    'VERSION_FROM'  => 'Snippet.pm',
    'PREREQ_PM'     => {
                              DBI => 0.0,
                              Class::MethodMaker => 0.0,
                              Term::Interact => 0.43,
                       },
    ## Add these new keywords supported since 5.005
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'Snippet.pm',
            AUTHOR        => 'Phil R Lawrence <prl ~AT~ cpan ~DOT~ org>'
          )
        : ()
    ),
);
