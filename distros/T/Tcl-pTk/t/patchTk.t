use warnings;
use strict;
use Test;
use Tcl;
use Tcl::pTk;
#$Tcl::pTk::DEBUG = 1;

print "# Test for RT #127120 workaround:\n"
    . "# Patch older Aqua Tk at runtime\n";

# If an older version of Tk is in use, check that
# certain patches get applied by Tcl::pTk at runtime

# Separate interpreter to check Tk without it being patched by Tcl::pTk
my $interp = Tcl->new;
$interp->Init;
# TODO: check if `package require` failed
die $@ unless $interp->Eval('package require Tk');
my $tk_version = $interp->GetVar('tk_version');

# check if old Aqua Tk and incorrect bindings are present
unless ($interp->Eval('tk windowingsystem') eq 'aqua') {
    print "1..0 # Skipped: Not using Aqua Tk\n";
    exit;
} else {
    # Check for affected versions of Tk
    unless (
        ($tk_version eq '8.4')
        or (
            ($tk_version eq '8.5')
            and ($interp->Eval('package vcompare $tk_patchLevel 8.5.16') == -1)
        ) or (
            ($tk_version eq '8.6')
            and ($interp->Eval('package vcompare $tk_patchLevel 8.6.1') == -1)
        )
    ) {
        print "1..0 # Skipped: Version of Tk present is not affected\n";
        exit;
    } else {
        plan tests => 2;

        ok(
            $interp->Eval('event info <<PasteSelection>>'),
            '<ButtonRelease-2>',
            'Affected Tk version present, verify that it should be patched',
        );
        
        my $TOP = MainWindow->new();
        ok(
            $TOP->interp->Eval('event info <<PasteSelection>>'),
            '<ButtonRelease-3>',
            'Verify that Tk was successfully patched by Tcl::pTk',
        );
    }
}


