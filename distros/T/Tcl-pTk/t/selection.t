#!/usr/local/bin/perl -w

use Tcl::pTk;
#use Tk;

use Test;
plan tests => 9;

$| = 1; # Pipes Hot
my $top = MainWindow->new;
#$top->option('add','*Text.background'=>'white');

my $t = $top->Scrolled('Text',"-relief" => "raised",
                     "-bd" => "2",
                     "-setgrid" => "true");


$t->pack(-expand => 1, "-fill"   => "both");

my $text = "This window is a text widget.  It displays one or more
lines of text and allows you to edit the text.";

$t->insert("0.0",$text);


#$top->after(1000,sub{$top->destroy});

$t->selectAll();

my $sel = $t->SelectionGet;
ok($sel, $text."\n", "Unexpected text returned from SelectionGet");
#print "SelectAll = '$sel'\n";

$t->tagRemove('sel','1.0','end');
$t->tagAdd('sel','1.0','1.10');
$sel = $t->SelectionGet();
#print "SelectPartial = '$sel'\n";
ok($sel, "This windo", "Unexpected partial selection");


$t->SelectionClear();
$sel = eval{ $t->SelectionGet();};
$sel ||= '';
ok($sel, '', "Unexpected text after SelectionClear");
#print "SelectClear = '$sel'\n";

$t->tagRemove('sel','1.0','end');
$t->tagAdd('sel','1.0','1.10');




my $owner = $t->SelectionOwner();
#print "selection owner = '$owner' ref = ".ref($owner)."\n";
ok(ref($owner), 'Tcl::pTk::Text', "Unexpected object type for SelectionOwner");

# Test the clipboard
$t->tagRemove('sel','1.0','end');
$t->tagAdd('sel','1.0','1.10');
my $val = $t->clipboardCopy;
ok($val, "This windo", "Unexpected results of clipboardCopy");
#print "clip = $val\n";

my $get = $t->clipboardGet();
ok($val, "This windo", "Unexpected results of clipboardGet");
#print "clip = $get\n";


###### SelectionHanldle Test #####
$t->SelectionOwn( -selection => 'CLIPBOARD'); # Make sure $t owns the selection

# Setup SelectionHandle Callback
$t->SelectionHandle( -selection => 'CLIPBOARD',
#$t->interp->call('selection', 'handle', -selection  => 'CLIPBOARD', $t,
         sub{
                my @args = @_;
                #print "selection handle args ".join(", ", @args)."\n";
                
                ok($args[0], 0, "1st SelectionHandle Arg is zero");
                ok($args[1] =~ /^\d+$/, 1, "2nd SelectionHandle Arg is number");

                return "Selection Handle Return";
        }
);
$sel = $t->SelectionGet(-selection => 'CLIPBOARD');
ok( $sel, "Selection Handle Return", "Selection Returns the right value");

#MainLoop;


