
use strict;
use Test;
use Tcl::pTk; 

# Test to see if the tclVersion and tclPatchlevel methods work

plan tests => 2;


my $TOP = MainWindow->new();


my $version = $TOP->tclVersion;
#print "version = '$version'\n";
ok(defined($version) and length($version) > 0);

my $patchlevel = $TOP->tclPatchlevel;
#print "patchlevel = '$patchlevel'\n";
ok(defined($patchlevel) and length($patchlevel) > 0);

