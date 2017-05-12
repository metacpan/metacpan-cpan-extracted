# Run this program to generate a makefile.  See "perldoc perlmodinstall"
#
# Time-stamp: "2008-04-08 22:47:11 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	    => 'Net::Clickatell',
    'VERSION_FROM'  => 'lib/Net/Clickatell.pm',
    'ABSTRACT_FROM' => 'lib/Net/Clickatell.pm',
    'PREREQ_PM'     => {
        'LWP'                 => 0,
    },
);

__END__

