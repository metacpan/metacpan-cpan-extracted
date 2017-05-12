use inc::Module::Install;

RTx('RTx-EmailCompletion');
author('Nicolas Chuche <nchuche@barna.be>');
abstract('autocompletion on mail');
license('perl');
WriteAll( meta => 1 );

sub MY::postamble {
    package MY;
    "\npredist: all\n" .
    "\tpod2readme  lib/RTx/EmailCompletion.pm > README\n".
    "\tsvk log -v  > ChangeLog\n"
}

use File::Basename;
use File::Copy;

if ($RT::VERSION lt "3.8") {
    for my $src (glob("scriptaculous/*.js")) {
	print "\tcopy $src to html/NoAuth/js/\n";
	my $dest = "html/NoAuth/js/" . basename($src);
	copy $src => $dest;
    }
} else {
    my @scriptaculous = grep { $_ !~ /emailcompletion/ } glob("html/NoAuth/js/*.js");
    if (@scriptaculous) {
	print "\tdelete scriptaculous lib from target";
	unlink @scriptaculous
    } 
}
