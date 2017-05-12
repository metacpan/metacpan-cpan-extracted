$^O=~/win32|mswin/i and die("OS not supported.\n");
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'PDF::OCR2',
   VERSION_FROM => 'lib/PDF/OCR2.pm',
   ABSTRACT_FROM => 'lib/PDF/OCR2.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   

   # gen /usr/bin/pmused by Wed Jun 24 14:36:54 EDT 2009 
   PREREQ_PM => {
      'CAM::PDF'                          => '1.52',
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Path'                        => '2.07',
      'File::PathInfo::Ext'               => '1.27',
      'File::Which'                       => '0.05',
      'Image::OCR::Tesseract'             => '1.20',
      'LEOCHARRE::CLI2'                   => '1.07',
      'LEOCHARRE::Class2'                 => '1.19',
      'LEOCHARRE::Debug'                  => '1.02',
      'LEOCHARRE::Dir'                    => '1.07',
      'PDF::API2'                         => '2.015',
      'PDF::Burst'                        => '1.19',
      'PDF::GetImages'                    => '1.17',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/pdfcheck)],
);


