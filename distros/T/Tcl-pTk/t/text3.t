#!/usr/local/bin/perl -w

# Test for many of the commands/methods added to the text widget by
#    Tcl/pTk/Widget/Text.pm

#use Tk;
use Tcl::pTk;

use Test;
plan tests => 12;

$| = 1; # Pipes Hot
my $top = MainWindow->new;
#$top->option('add','*Text.background'=>'white');

my $t = $top->Scrolled('Text',"-relief" => "raised",
#my $t = $top->Text("-relief" => "raised",
                     "-bd" => "2",
                     "-setgrid" => "true");


$t->pack(-expand => 1, "-fill"   => "both");

$t->tagConfigure( "underline","-underline","on");
$t->tag("configure", "hideable", -elide => 0, -foreground => 'blue');

my $origContents = "This window is a text widget.  It displays one or more
lines of text and allows you to edit the text.  Here is a summary of the
things you can do to a text widget:";

$t->insert("0.0", $origContents,'hideable');


my @names = $t->tagNames();
ok( join(", ", @names), 'sel, underline, hideable');
#print join(", ", @names)."\n";

# Contents Checks
my $contents = $t->Contents();
ok( $contents, $origContents."\n");
$origContents = "This is some new text";
$t->Contents($origContents);
$contents = $t->Contents();
ok( $contents, $origContents."\n");

# Test deleteTextTaggedWith
$t->insert("end", $origContents,'hideable');
$t->DeleteTextTaggedWith('hideable');
ok( $contents, $origContents."\n");

# deleteSelected
$t->selectAll();
$t->deleteSelected();
$contents = $t->Contents();
ok( $contents, ''."\n");

# DeleteToEndOfLine
$t->Contents("This is bogus, dude");
$t->markSet('insert', "1.5");
$t->deleteToEndofLine();
$contents = $t->Contents();
ok( $contents, 'This '."\n");

# FindAll
$t->Contents("This Really is bogus, dude Really");
$t->FindAll(-exact, -nocase, 'Really');
$t->deleteSelected();
$contents = $t->Contents();
ok( $contents, 'This  is bogus, dude '."\n");

# Find and Replace All
$t->Contents("This Really is bogus, dude Really");
$t->FindAndReplaceAll(-exact, -nocase, 'Really', 'Not');
$contents = $t->Contents();
ok( $contents, 'This Not is bogus, dude Not'."\n");

my $exists = $t->markExists('insert');
ok( $exists, 1);

# openLine
$t->Contents("This is bogus, dude");
$t->markSet('insert', "1.5");
$t->openLine();
$contents = $t->Contents();
ok( $contents, "This \nis bogus, dude"."\n");

# SetCursor
$t->Contents("This is bogus, dude");
$t->markSet('insert', "0.0");
$t->SetCursor("1.5");
$t->deleteToEndofLine();
$contents = $t->Contents();
ok( $contents, 'This '."\n");

# unselectAll
$t->Contents("This is bogus, dude");
$t->selectAll();
$t->unselectAll();
$t->deleteSelected();
$contents = $t->Contents();
ok( $contents, 'This is bogus, dude'."\n");

# Quit after two seconds
$top->after(2000,
        sub{
                
                $top->destroy;
        });


MainLoop;


