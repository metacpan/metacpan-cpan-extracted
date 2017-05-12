#!/usr/bin/perl -w
#
# Perl/Tk version of Tix4.1.0/demos/samples/Tree.tcl.  Not quite as
# nice as the Tix version: fonts and colors are different, and the
# collapse/expand buttons are higlighted differently.
#


use strict;
use Tcl::pTk;
use Tcl::pTk::Tree;
use Test;


my $top = MainWindow->new( -title => "Tree" );

# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');

unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan tests => 4;


$| = 1; # Pipes hot

my $tree = $top->Scrolled( qw/Tree -separator \ 
                           -scrollbars osoe / );

#my $tree = $top->Tree( qw/ -separator \  /);

$tree->pack( qw/-expand yes -fill both -padx 10 -pady 10 -side top/ );

my @directories = qw( C: C:\Dos C:\Windows C:\Windows\System );

foreach my $d (@directories) {
    my $text = (split( /\\/, $d ))[-1]; 
    $tree->add( $d,  -text => $text, -image => $tree->Getimage("folder") );
}

# Add a window type
$tree->add("C:\\Windows\\System\\WindowType", -itemtype => 'window', -window => $tree->Label(-text => "WindowType", -bg => 'white'));

$tree->configure( -command => sub { print "@_\n" } );


# The tree is fully expanded by default.
$tree->autosetmode();


my $ind = $tree->cget(-indicatorcmd);
ok(ref($ind), "Tcl::pTk::Callback", "-indicatormcd returns callback");

ok(1, 1, "Tree Widget Creation");

# Get the window back and make sure it is a widget type
my $window = $tree->entrycget("C:\\Windows\\System\\WindowType", -window);
ok(ref($window), "Tcl::pTk::Label", "entrycget -window returns widget");

# Check that a image widget is returned
my $image = $tree->entrycget("C:\\Windows\\System", -image);
ok(ref($image), "Tcl::pTk::Photo", "entrycget image returns photo object");
 
$top->after(1000,sub{$top->destroy});

MainLoop();
