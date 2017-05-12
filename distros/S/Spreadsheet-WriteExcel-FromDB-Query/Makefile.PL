use ExtUtils::MakeMaker;

my $me = "lib/Spreadsheet/WriteExcel/FromDB/Query.pm";

WriteMakefile(
    'NAME'		=> 'Spreadsheet::WriteExcel::FromDB::Query',
    'VERSION_FROM'	=> $me, 
    'PREREQ_PM'		=> { 
                             'Spreadsheet::WriteExcel::Simple' => 0.02,
                             'Spreadsheet::WriteExcel::FromDB' => '1.00'
                           },
    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Christopher Kois <cpkois@cpan.org>') 
    ),
);
