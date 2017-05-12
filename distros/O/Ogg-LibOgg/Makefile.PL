use 5.008;
use ExtUtils::MakeMaker;

use strict;
use warnings;
use Config;
use File::Spec::Functions;

WriteMakefile(
    NAME              => 'Ogg::LibOgg',
    VERSION_FROM      => 'lib/Ogg/LibOgg.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Ogg/LibOgg.pm', # retrieve abstract from module
       AUTHOR         => 'Vigith Maurice <vigith@cpan.org>') : ()),
    LIBS              => ['-logg'],
    DEFINE            => '',
    INC               => '-I/opt/local/include -I/usr/local/lib -I/usr/lib',

);

