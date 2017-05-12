#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 6;

use Tcl;
use File::Spec::Functions;

my $tcl = Tcl->new;

ok($tcl);
if ($^O eq 'cygwin') {
    my $cpath = $tcl->Eval("info nameofexecutable");
    $cpath = `cygpath -u '$cpath'`;
    chomp($cpath);
    ok($cpath, canonpath($^X));
} else {
    ok(canonpath($tcl->Eval("info nameofexecutable")), canonpath($^X));
}
ok($tcl->Eval("info exists tcl_platform"), 1);

my $tclversion = $tcl->Eval("info tclversion");
ok($tclversion =~ /^8\.\d+$/);
ok(substr($tcl->Eval("info patchlevel"), 0, length($tclversion)), $tclversion);
ok(length($tcl->Eval("info patchlevel")) > length($tclversion));
