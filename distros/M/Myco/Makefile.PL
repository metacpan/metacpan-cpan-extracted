
# $Id: Makefile.PL,v 1.1.1.1 2004/11/22 19:16:00 owensc Exp $

use ExtUtils::MakeMaker;


sub module_prereqs {
    # adapted from modules.pl from Bricolage

    my $prereqs;
    my @mod;
    open(ADM, "lib/Myco/Admin.pod")
	or die "Unable to open lib/Myco/Admin.pod : $!";
    # seek to start of modules
    while (<ADM>) {
	last if /START MODULE LIST/;
    }
    # read in modules
    while (<ADM>) {
	if (/^=item\s+(\S+)(?:\s+([\d\.]+))?(?:\s+(\(optional\)))?/) {
	    $prereqs->{$1} = $2 || 0;
	} elsif (/END MODULE LIST/) {
	    last;
	}
    }
    close ADM;
    return $prereqs;
}



WriteMakefile(
	      NAME	   => 'Myco',
	      VERSION_FROM => 'lib/Myco.pm', # finds $VERSION
	      PREREQ_PM    => module_prereqs(),
	      PREREQ_FATAL => 1,
);
