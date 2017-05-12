# $Id: Makefile.PL,v 1.2 2001/12/13 00:42:54 mpeppler Exp $
#
# $Log: Makefile.PL,v $
# Revision 1.2  2001/12/13 00:42:54  mpeppler
# version 0.53
#
# Revision 1.1  1999/11/25 00:20:23  mpeppler
# Initial revision
#
# Revision 1.2  1998/10/16 18:23:26  mpeppler
# Added check for Sybase::CTlib existence.
#
#

eval {
    require Sybase::CTlib;
};
die "I can't find Sybase::CTlib.\nYou must install sybperl 2.xx before being able to use this module\n" if $@;

use ExtUtils::MakeMaker;

# Ask user about Sybase access information.
configPwd();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Sybase::Simple',
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
);



sub configPwd {
    open(IN, "PWD") || die "Can't open PWD: $!";
    my %pwd;
    while(<IN>) {
	chomp;
	next if(/^\s*\#/);
	next if(/^\s*$/);
	my ($key, $val) = split(/=/, $_);
	$pwd{$key} = $val || "undef";
    }
    close(IN);
    select(STDOUT); $| = 1;

    print "The Sybase::Simple module need access to a Sybase server to run the tests.\n";
    print "To clear an entry please enter 'undef'\n";
    print "Sybase server to use (default: $pwd{SRV}): ";
    $pwd{SRV} = getAns() || $pwd{SRV};
    print "User ID to log in to Sybase (default: $pwd{UID}): ";
    $pwd{UID} = getAns() || $pwd{UID};
    print "Password (default: $pwd{PWD}): ";
    $pwd{PWD} = getAns() || $pwd{PWD};

    open(OUT, ">PWD") || die "Can't open PWD: $!";
    print OUT <<EOF;
# This file contains optional login id, passwd and server info for the test
# programs:
# You probably don't want to have it lying around after you've made
# sure that everything works OK.

EOF
    foreach (keys %pwd) {
	$pwd{$_} = '' if $pwd{$_} eq 'undef';
	print OUT "$_=$pwd{$_}\n";
    }
    close(OUT);
}

sub getAns {
    my $ans = <>;
    chomp($ans);
    $ans;
}
