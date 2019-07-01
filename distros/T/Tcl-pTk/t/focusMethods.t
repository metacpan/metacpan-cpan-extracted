use warnings;
use strict;

# Test for focus, focusCurrent, focusNext, focusPrev,
# and focusFollowsMouse methods in Tcl::pTk

use Test;

plan test => 7;

#use Tk; # verified against Perl/Tk for compatability
use Tcl::pTk;

my $mw = MainWindow->new;

# Three entry widgets, which can normally be focused by pressing tab
# or shift+tab (note that pressing tab on entry3 focuses on entry1,
# and pressing shift+tab on entry1 focuses on entry3)
my $entry1 = $mw->Entry->pack;
my $entry2 = $mw->Entry->pack;
my $entry3 = $mw->Entry->pack;
$mw->update;

$entry1->focus;
$mw->update;
ok($mw->focusCurrent, $entry1, 'initial focus on entry1 failed');

$entry1->focusNext;
$mw->update;
ok($mw->focusCurrent, $entry2, 'focusNext from entry1 to entry2 failed');

$entry2->focusNext;
$mw->update;
ok($mw->focusCurrent, $entry3, 'focusNext from entry2 to entry3 failed');

$entry3->focusPrev;
$mw->update;
ok($mw->focusCurrent, $entry2, 'focusPrev from entry3 to entry2 failed');

$entry2->focusPrev;
$mw->update;
ok($mw->focusCurrent, $entry1, 'focusPrev from entry2 to entry1 failed');

$entry3->eventGenerate('<Enter>');
$entry3->update;
ok(
    $mw->focusCurrent, $entry1,
    'before focusFollowsMouse: ' .
    'failed to keep focus on entry1 while entering entry3'
);

$mw->focusFollowsMouse;

$entry3->eventGenerate('<Enter>');
$entry3->update;
ok($mw->focusCurrent, $entry3,
    'after focusFollowsMouse: ' .
    'failed to focus on entry3 by entering'
);


MainLoop if (@ARGV);
