use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Schedule::Cronchik',
    'VERSION_FROM' => 'Cronchik.pm',
    'PREREQ_PM' => {},
    ($] >= 5.005 ?
        (AUTHOR => 'Ivan Frolcov <ifrol\@cpan.org>') : ()),
);