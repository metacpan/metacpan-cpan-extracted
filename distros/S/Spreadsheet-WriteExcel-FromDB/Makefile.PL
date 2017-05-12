use ExtUtils::MakeMaker;

my $me = "lib/Spreadsheet/WriteExcel/FromDB.pm";

WriteMakefile(
    'NAME'		=> 'Spreadsheet::WriteExcel::FromDB',
    'VERSION_FROM'	=> $me, 
    'PREREQ_PM'		=> { 
                             'Spreadsheet::WriteExcel::Simple' => 0.02,
                           },
    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Tony Bowden <kasei@tmtm.com>') 
    ),
);
