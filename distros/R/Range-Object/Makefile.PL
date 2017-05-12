use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Range::Object',
    VERSION_FROM      => 'lib/Range/Object.pm',
    PREREQ_PM         => {
        'Test::More'    => 0,
        'List::Util'    => 0,
        'Date::Simple'  => '3.00',
        'Date::Range'   => '1.40',
    },
    META_MERGE => {
      resources   => {
        bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Range-Object',
        repository  => 'http://github.com/nohuhu/Range-Object',
      },
    },
    ABSTRACT => 'Manipulate ranges of different objects using the same API',
    AUTHOR   => 'Alexander Tokarev <tokarev@cpan.org>',
    LICENSE  => 'perl',
);
