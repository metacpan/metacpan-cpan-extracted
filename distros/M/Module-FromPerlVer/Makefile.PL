
# this is the minimum version guaranteed to work with
# File::Copy and FindBin::libs;

use 5.008;
use strict;
use version;

use ExtUtils::MakeMaker;

my $path    = 'lib/Module/FromPerlVer.pm';

my $version = version->parse( 'v0.0.2' );

WriteMakefile
(
    NAME            => 'Module::FromPerlVer',
    ABSTRACT_FROM   => $path,
    VERSION         => "$version",
    LICENSE         => 'perl',
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

		qw
        (
            Carp                    0
            Cwd                     0
            File::Basename          0
            File::Copy::Recursive   0
            File::Find              0
            FindBin                 0
            List::Util              0
            NEXT                    0
            Scalar::Util            0
            Symbol                  0
            Test::More              0
            strict                  0
            version                 0
        )
    },
);

__END__
