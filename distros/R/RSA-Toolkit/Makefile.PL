BEGIN { require 5.008 }

use warnings;
use strict;
use ExtUtils::MakeMaker;

my $path = '/opt/ace/utils/toolkit';

if ($^O eq 'MSWin32') {
	print "The current version of this module has not been tested in windows platform and it may not be installed correctly\n";
}


WriteMakefile(
    NAME              => 'RSA::Toolkit',
    VERSION_FROM      => 'lib/RSA/Toolkit.pm',
    PREREQ_PM         => {},
    ABSTRACT          => 'Perl extension for RSA Administration Toolkit',
    AUTHOR            => 'Pan Yu <xiaocong[at]vip.163.com>',
    LIBS              => ['-lm -lc -lw -lsocket -lnsl -ldl'],#-lprompt_api
    DEFINE            => '-DUNIX -DSOL',
    INC               => "-I$path",
    LICENSE           => 'Perl',
    MYEXTLIB          => "$path/ace_api.a"
);



