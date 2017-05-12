use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $author1 = 'Megan Charity <charityml@vcu.edu'; 
my $author2 = 'Bridget McInnes <btmcinnes@vcu.edu';


WriteMakefile(
    'NAME'                => 'NanoB2B::NER',
    'VERSION_FROM'        => 'lib/NanoB2B/NER.pm',
    'PREREQ_PM' => {
        'MetaMap::DataStructures' => '0.03',
	'File::Path' => '0',
	'Term::ANSIColor' => '0',
	'List::MoreUtils' => '0'
	
    }, 

    'EXE_FILES'            => [("utils/NanoB2BNER.pl")], 
    'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT'   => 'lib/NanoB2B/NER.pm', 
      'AUTHOR'          => "$author1, $author2") : ())); 
 

