#!/pro/bin/perl

use strict;
use warnings;

foreach my $vf (glob ("/etc/*[-_][rRvV][eE][lLrR]*"), "/etc/issue",
                "/etc.defaults/VERSION", "/etc/VERSION", "/etc/release") {
    if (-d $vf) {
	(my $d = $vf) =~ s{.*/}{};
	print "mkdir $d\n";
	foreach my $f (grep { -f } glob "$vf/*") {
	    open my $fh, "<", $f or next;
	    $f =~ s{.*/}{};
	    print "cat > $d/$f <<EOFV\n", <$fh>, "EOFV\n";
	    }
	next;
	}
    open my $fh, "<", $vf or next;
    (my $lf = $vf) =~ s{.*/}{};
    print "cat > $lf <<EOFV\n", <$fh>, "EOFV\n";
    }

