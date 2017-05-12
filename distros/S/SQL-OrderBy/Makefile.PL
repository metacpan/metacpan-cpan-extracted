use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'SQL::OrderBy',
    'VERSION_FROM' => 'lib/SQL/OrderBy.pm',
    'PREREQ_PM'    => {},
    ($] >= 5.005
        ? (ABSTRACT_FROM => 'lib/SQL/OrderBy.pm',
           AUTHOR        => 'Gene Boggs <gene@cpan.org>')
        : ()),
);
