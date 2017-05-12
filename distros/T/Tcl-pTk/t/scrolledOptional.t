#!/usr/local/bin/perl -w

# Test case for the 'optional' scrollbars options of 'Scrolled'.
#  This creates a scrolled widget with small geometry, then a large geometry.
#    For the small geometry, the scrollbars should be present.
#    For the large geometry, the scrollbars should be  removed

use Tcl::pTk;

use Test;
plan tests => 4;

$| = 1; # Pipes Hot
my $top = MainWindow->new;

$top->geometry('20x20');


my $t = $top->Scrolled('Text',"-relief" => "raised", -scrollbars => 'osoe',
                     "-bd" => "2",
                     "-setgrid" => "true", -wrap => 'none');

$t->insert("0.0", "This window is a text widget.  It displays one or more
lines of text and allows you to edit the text.  Here is a summary of the
things you can do to a text widget:");

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

$t->pack(-expand => 1, "-fill"   => "both");


$top->after(1000, sub{
                ok($t->{packysb}, 1, "y scroll bar present");
                ok($t->{packxsb}, 1, "x scroll bar present");
});

$top->after(1500, sub{
                $top->geometry('80x40');
});

$top->after(2000, sub{
                ok($t->{packysb}, 0, "y scroll bar auto-removed");
                ok($t->{packxsb}, 0, "x scroll bar auto-removed");
});

$top->after(2500,sub{$top->destroy});

MainLoop;


