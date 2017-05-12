# Test script that checks for a particular bug where a simple scrolled widget
#   would get pack errors if the Delegates 'DEFAULT' was set.

package Tcl::pTk::TextTest;

use strict;
use vars qw($VERSION @ISA);

$VERSION = substr(q$Revision: 2.8 $, 10) . "";

use Tcl::pTk;
use Tcl::pTk::Derived;
use Tcl::pTk::Frame;
@ISA = qw(Tcl::pTk::Derived Tcl::pTk::Frame);

Construct Tcl::pTk::Widget 'TextTest';

sub Populate {
    my ($cw, $args) = @_;


    $cw->SUPER::Populate($args);


    my $t = $cw->Text()->pack(-fill => 'both' , -expand => 'yes');
    #$t->tagConfigure('search', -foreground => 'red');

    # reorder bindings: private widget bindings first
    #$t->bindtags([$t, grep { $_ ne $t->PathName } $t->bindtags]);


    $cw->Delegates(
                   'DEFAULT'   => $t,
		  );


    $cw->ConfigSpecs(
		'DEFAULT'      => [$t]
		);

    $cw;
}

package main;

use Tcl::pTk;
use Test;

plan tests => 1;

my $TOP = MainWindow->new();


my $test = $TOP->Scrolled('TextTest')->pack();

$test->update;

ok(1);
