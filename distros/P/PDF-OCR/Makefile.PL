use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'PDF::OCR',
   VERSION_FROM => 'lib/PDF/OCR.pm',


   # gen /usr/bin/pmused by Thu Aug 14 14:07:12 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
#      'Devel::AssertOS'                   => '1',
#      'Devel::CheckOS'                    => '1.43',
#      'Exporter'                          => '5',
      'File::Copy'                        => '2',
      'File::Find::Rule'                  => '0.30',
      'File::Path'                        => '1',
      'File::Slurp'                       => '0',
      'File::Spec'                        => '3.24',
      'File::Which'                       => '0.05',
      'Image::OCR::Tesseract'             => '1.13',
      'LEOCHARRE::CLI'                    => '1.18',
      'PDF::API2'                         => '2.015',
      'PDF::Burst'                        => '1.10',
      'PDF::GetImages'                    => '1.01',
      'Smart::Comments'                   => '1.0.2',
      'Test::Simple'                      => '0.7',
   },


   EXE_FILES => [qw(bin/ocr
		bin/pdf2ocr
		bin/pdf2ocrturntotext
		bin/pdfgetext)],
);


