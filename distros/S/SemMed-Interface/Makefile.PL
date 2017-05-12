use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $author1 = 'Bridget McInnes <btmcinnes@vcu.edu>';
my $author2 = 'Andriy Mulyar <andriy.mulyar@gmail.com>';


	WriteMakefile(
	    NAME             => 'SemMed::Interface',
    VERSION_FROM     => 'lib/SemMed/Interface.pm',
	'PREREQ_PM' => {
        'Heap::Priority' => '0',
    }, 

    'EXE_FILES'            => [("utils/semmed-interface-example.pl")], 
    'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT_FROM'   => 'lib/SemMed/Interface.pm', 
      'AUTHOR'          => "$author1, $author2") : ())

);
