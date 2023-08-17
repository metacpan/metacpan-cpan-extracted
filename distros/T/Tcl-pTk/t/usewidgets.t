use warnings;
use strict;
use Test;
BEGIN { plan tests => 9 };

#use Tk;
use Tcl::pTk;

BEGIN {
    # Some widgets with .pm files in Perl/Tk and Tcl::pTk
    my @l = qw/DialogBox LabEntry Frame/;

    # Some widgets with .pm files in Perl/Tk but not Tcl::pTk
    push @l, qw/Label Button Checkbutton Radiobutton Scrollbar Spinbox/;

    foreach my $foo (@l) {
        unless (eval <<"EOS") {
            #use Tk::widgets qw/$foo/;
            use Tcl::pTk::widgets qw/$foo/;
            ok(1);
            1;
EOS
            my $err = $@ || 'unknown error';
            print "# $err";
            ok(0);
        }
    }
};
