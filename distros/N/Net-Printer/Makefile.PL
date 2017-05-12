# -*- mode: cperl -*-

#
# $Id: 0445ac71fc70d878504fae448bbf44ff903ec58a $
#

use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
        NAME          => 'Net::Printer',
        AUTHOR        => 'Christopher M. Fuhrman <cfuhrman@panix.com>',
        LICENSE       => 'bsd',
        VERSION_FROM  => 'lib/Net/Printer.pm',
        ABSTRACT_FROM => 'lib/Net/Printer.pm',
        META_MERGE    => {
                'resources' => {
                       bugtracker =>
"http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Printer",
                       repository => "https://github.com/cfuhrman/net-printer",
                       license =>
"https://github.com/cfuhrman/net-printer/raw/master/LICENSE"
                },
        },
        dist => {
                  COMPRESS => 'gzip -9f',
                  SUFFIX   => 'gz',
        },
        clean => { FILES => 'Net-Printer-*' },
);

