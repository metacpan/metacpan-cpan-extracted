# $Id: Makefile.PL,v 1.4 2003/12/03 15:39:44 autarch Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::SFTP',
    DISTNAME => 'Net-SFTP',
    VERSION_FROM => 'lib/Net/SFTP.pm',
    AUTHOR => 'Dave Rolsky <autarch@urth.org>',
    ABSTRACT => 'Secure File Transfer Protocol client',
    PREREQ_PM => {
        'Net::SSH::Perl' => '1.24',
    },
);
