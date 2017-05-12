use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'  => 'Spreadsheet::WriteExcel::FromXML',
    'VERSION_FROM' => 'lib/Spreadsheet/WriteExcel/FromXML.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Spreadsheet::WriteExcel' => 0.41, 
	                'OLE::Storage_Lite'       => 0.11,
		        'XML::Parser'             => 2.31
                      },
);
