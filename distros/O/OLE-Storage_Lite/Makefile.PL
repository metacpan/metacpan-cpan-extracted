use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    'AUTHOR'        => 'Kawai Takanori (kwitknr@cpan.org)',
    'ABSTRACT'      => 'Read and write OLE storage files.',
    'NAME'          => 'OLE::Storage_Lite',
    'VERSION_FROM'  => 'lib/OLE/Storage_Lite.pm',
    'NEEDS_LINKING' => 0,
    'PREREQ_PM'     => {
        'perl' => '5.006',
    },
    'dist'          => {COMPRESS => 'gzip --best', SUFFIX => 'gz'},


);
