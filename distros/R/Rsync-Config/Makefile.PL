use ExtUtils::MakeMaker qw ( WriteMakefile );

use File::Spec;
use File::Basename qw/dirname/;
use lib File::Spec->catdir(dirname($0), 'inc');

use ExtUtils::AutoInstall (
        -core => [
             'Scalar::Util'        => 0,
             'English'             => 0,
             'Exception::Class'    => 0,
             'CLASS'               => 0,
           ]
);

WriteMakefile(
	AUTHOR       => 'Subredu Manuel <diablo@packages.ro>',
	NAME         => 'Rsync::Config',
	VERSION_FROM => 'lib/Rsync/Config.pm',
	);
