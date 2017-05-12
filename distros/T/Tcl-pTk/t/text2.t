#!/usr/local/bin/perl -w

use Tcl::pTk;

use Test;
plan tests => 5;

$| = 1; # Pipes Hot
my $top = MainWindow->new;
#$top->option('add','*Text.background'=>'white');

my $t = $top->Scrolled('Text',"-relief" => "raised",
#my $t = $top->Text("-relief" => "raised",
                     "-bd" => "2",
                     "-setgrid" => "true");

my $m = $t->Menu();
$m->add("command", "-label" => "Open", "-underline" => 0,
        "-command" => \&sayopen);
$m->add("command", "-label" => "Close", "-underline" => 0,
        "-command" => \&sayclose);
$m->add("separator");
$m->add("command", "-label" => "Selection", "-underline" => 0,
        "-command" => \&showsel);
$m->add("separator");
$m->add("command", "-label" => "Exit", "-underline" => 1,
        "-command" => \&doexit);

$t->pack(-expand => 1, "-fill"   => "both");

$t->tagConfigure( "underline","-underline","on");
$t->tag("configure", "hideable", -elide => 0, -foreground => 'blue');

$t->insert("0.0", "This window is a text widget.  It displays one or more
lines of text and allows you to edit the text.  Here is a summary of the
things you can do to a text widget:",'hideable');

$t->insert(end => "

1. Insert text. Press mouse button 1 to set the insertion cursor, then
type text.  What you type will be added to the widget.  You can backspace
over what you've typed using either the backspace key, the delete key,
or Control+h.

2. Resize the window.  This widget has been configured with the \"setGrid\"
option on, so that if you resize the window it will always resize to an
even number of characters high and wide.  Also, if you make the window
narrow you can see that long lines automatically wrap around onto
additional lines so that all the information is always visible.

3. Scanning. Press mouse button 2 in the text window and drag up or down.
This will drag the text at high speed to allow you to scan its contents.

4. Select. Press mouse button 1 and drag to select a range of characters.
Once you've released the button, you can adjust the selection by pressing
button 1 with the shift key down.  This will reset the end of the
selection nearest the mouse cursor and you can drag that end of the
selection by dragging the mouse before releasing the mouse button.
You can double-click to select whole words, or triple-click to select
whole lines.

5. Delete. To delete text, select the characters you'd like to delete
and type Control+d.

6. Copy the selection. To copy the selection either from this window
or from any other window or application, select what you want, click
button 1 to set the insertion cursor, then type Control+v to copy the
selection to the point of the insertion cursor.

You can also bind commands to tags. Like press button 3 for menu ");

&insertwtag($t,"here","underline");

$t->tagBind("underline","<3>", [sub { shift; shift->Post(@_)},$m,Ev(X),Ev(Y)] );


# Check for entrycget -menu operation on the menu
my $menu = $t->menu;
my $m2 = $menu->entrycget(3, '-menu');
#print "menu = $m\n";
#print "ref menu = ".ref($m)."\n";
ok(ref($m2), 'Tcl::pTk::Menu', "entrycget -menu returns widget ref");


# Check return of 2-arg bind for items
my $bindRet = $t->tagBind('underline', '<3>');
#print "bindRet = $bindRet\n";
ok(ref($bindRet), 'Tcl::pTk::Callback', "text 2-arg tagBind returns callback");

$bindRet = $t->tag('bind','underline', '<3>');
#print "bindRet = $bindRet\n";
ok(ref($bindRet), 'Tcl::pTk::Callback', "text 2-arg tag bind returns callback");

# Check return of 1-arg tagBind for items
my @bindRet = $t->tagBind('underline');
#print "bindRet = $bindRet\n";
ok(join(", ",@bindRet), '<Button-3>', "text 1-arg tagBind returns list of sequences");



$t->bind("<Any-Enter>", sub { $t->focus });

# Setup so we can tell that OnDestroy callbacks happen before <Destroy> bindings
my $destroyText = '';
$t->Subwidget('text')->OnDestroy(sub { 
        print "Destroyed!\n"; 
        $destroyText  .= "OnDestroy";
        # print $t->get('1.0','end') # Doesn't work for Tcl/pTk 8.5
});

$t->Subwidget('text')->bind('<Destroy>', sub{
                $destroyText .= "Binding";
});

$t->tag("bind", "hideable","<2>", sub {
    $t->tagConfigure(hideable => -elide => 1, -foreground => 'pink')}
);

$top->after(1000,sub{$top->destroy}) unless(@ARGV); # Quit after a second, unless something on the command line (i.e. debugging)
MainLoop;

ok($destroyText, 'OnDestroyBinding', "OnDestroy and <Destroy> event order");

sub insertwtag {
  local($w,$text,$tag) = @_;
  my $start = $w->index("insert");
  #print "start=$start\n";
  $w->insert("insert",$text);
  $w->tag("add",$tag,$start,"insert");
}


sub sayopen { print "Open something\n" }
sub sayclose { print "Close something\n" }
sub showsel  { my @info = $t->tagRanges('sel');
               if (@info)
                {
                 print "start=$info[0] end=$info[1]\n"
                }
             }
sub doexit
{
 $top->destroy;
}
