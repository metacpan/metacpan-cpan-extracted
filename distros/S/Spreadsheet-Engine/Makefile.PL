use ExtUtils::MakeMaker;

require 5.007003;

WriteMakefile(
    NAME          => 'Spreadsheet::Engine',
    AUTHOR        => 'Tony Bowden <tony@tmtm.com>',
    VERSION_FROM  => 'lib/Spreadsheet/Engine.pm',
    ABSTRACT_FROM => 'lib/Spreadsheet/Engine.pm',
    LICENSE       => 'Artistic License 2.0',
    PREREQ_PM     => {},
);

