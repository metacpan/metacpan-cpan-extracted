use lib './inc';
use Devel::AssertOS qw/Unix/;
use Devel::AssertEXE qw/pdfimages/;

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'PDF::GetImages',
   VERSION_FROM => 'lib/PDF/GetImages.pm',


   # gen /usr/bin/pmused by Thu Sep 25 16:39:49 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1.03',
      'File::Copy'                        => '2.08',
      'File::Find::Rule'                  => '0.30',
      'File::Path'                        => '2.04',
      'File::Spec'                        => '3.17',
      'File::Which'                       => '0.05',
      'Test::Simple'                      => '0.8',
   },


   EXE_FILES => [],
);


