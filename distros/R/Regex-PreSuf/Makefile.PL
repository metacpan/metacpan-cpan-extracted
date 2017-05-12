require 5;

use ExtUtils::MakeMaker;

use Cwd;

WriteMakefile(
    'NAME'         => 'Regex::PreSuf',
    'VERSION_FROM' => 'PreSuf.pm',
    'dist'         => { 'COMPRESS' => 'gzip' }
);
