# $Id: Makefile.PL,v 1.1.1.1 2003/07/03 13:42:22 matt Exp $

use strict;

use ExtUtils::MakeMaker;

unlink(".do_net");
if (prompt("Some of the tests do network checks. Would you like to run these?", "N") =~ /^y/i) {
    open(TOUCH, ">.do_net") || die $!;
    print TOUCH "This file just means we do the network checks. Remove it to turn them off\n";
    close TOUCH;
}

WriteMakefile(
    'NAME' => 'Net::SenderBase',
    'VERSION_FROM' => 'lib/Net/SenderBase.pm',
    'PREREQ_PM' => {
        'Net::DNS' => 0.23,
        'Test::More' => 0,
    },
    'ABSTRACT_FROM' => 'lib/Net/SenderBase.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);

