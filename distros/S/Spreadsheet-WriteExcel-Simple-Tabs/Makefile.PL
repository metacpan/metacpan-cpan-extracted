use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Spreadsheet::WriteExcel::Simple::Tabs',
    VERSION_FROM => 'lib/Spreadsheet/WriteExcel/Simple/Tabs.pm', # finds \$VERSION
    AUTHOR       => 'Michael R. Davis (domain=>michaelrdavis,tld=>com,account=>perl)',
    ABSTRACT     => 'Simple Interface to the Spreadsheet::WriteExcel Package',
    PREREQ_PM    => {
                     'Test::Simple'            => 0.44,
                     'IO::Scalar'              => 0, #package is IO-stringy
                     'Spreadsheet::WriteExcel' => 0,
                    },
);
