#!/usr/bin/perl

use strict;
use Test;

#Make sure the plan is known
BEGIN { plan tests => 79 };

#Load the necessary modules
use Carp;
ok(1);
use Term::ReadKey;
ok(2);
use Term::ANSIMenu;
ok(3);

#Create a test object
my $menu = Term::ANSIMenu->new();

#Test all accessors/mutators
my @list = ();
ok(40, $menu->width(40));
ok(25, $menu->height(25));
ok(1, $menu->space_after_title(1));
ok(1, $menu->space_after_items(1));
ok(1, $menu->space_after_status(1));
ok(1, $menu->spacious_items(1));
ok(1, $menu->cursor(1));
ok('?', $menu->cursor_char('?'));
@list = ('UP', 'PGUP');
ok(@list, @{$menu->up_keys(\@list)});
@list = ('DOWN', 'PGDN');
ok(@list, @{$menu->down_keys(\@list)});
@list = (['help0', sub { return 1 }],
         ['help1', sub { return 1 }]);
ok(@list, @{$menu->help(\@list)});
@list = ('F1', '?');
ok(@list, @{$menu->help_keys(\@list)});
@list = ('q', 'Q', 'CTRL-c');
ok(@list, @{$menu->exit_keys(\@list)});
ok(0, $menu->selection(0));
ok(1, $menu->selection_wrap(1));
@list = ('SPACE', 'ENTER');
ok(@list, @{$menu->selection_keys(\@list)});
@list = ('REVERSE');
ok(@list, @{$menu->selection_style(\@list)});
ok('WHITE', $menu->selection_fgcolor('WHITE'));
ok('BLACK', $menu->selection_bgcolor('BLACK'));
ok(0, $menu->leader(0));
ok(0, $menu->trailer(0));
ok('LTE ', $menu->shortcut_prefix('LTE '));
ok(' ', $menu->shortcut_postfix(' '));
ok('CTE', $menu->delimiter('CTE'));
ok('TTE', $menu->leader_delimiter('TTE'));
ok('BTE', $menu->trailer_delimiter('BTE'));
ok(' ', $menu->label_prefix(' '));
ok(' RTE', $menu->label_postfix(' RTE'));
ok('title', $menu->title('title'));
@list = ('BOLD');
ok(@list, @{$menu->title_style(\@list)});
ok('RED', $menu->title_fgcolor('RED'));
ok('GREEN', $menu->title_bgcolor('GREEN'));
ok('CENTER', $menu->title_align('CENTER'));
ok(1, $menu->title_fill(1));
ok(1, $menu->title_frame(1));
@list = ('BOLD');
ok(@list, @{$menu->title_frame_style(\@list)});
ok('RED', $menu->title_frame_fgcolor('RED'));
ok('GREEN', $menu->title_frame_bgcolor('GREEN'));
@list = (['1', 'First menu item', sub { return 1 }],
         ['2', 'Second menu item'],
         ['3', '', sub { return 1 }]);
ok(@list, @{$menu->items(\@list)});
@list = ('CLEAR');
ok(@list, @{$menu->item_style(\@list)});
ok('BLUE', $menu->item_fgcolor('BLUE'));
ok('CYAN', $menu->item_bgcolor('CYAN'));
ok('LEFT', $menu->item_align('LEFT'));
ok(1, $menu->item_fill(1));
ok(1, $menu->item_frame(1));
@list = ('CLEAR');
ok(@list, @{$menu->item_frame_style(\@list)});
ok('BLUE', $menu->item_frame_fgcolor('BLUE'));
ok('CYAN', $menu->item_frame_bgcolor('CYAN'));
ok('status', $menu->status('status'));
@list = ('CLEAR');
ok(@list, @{$menu->status_style(\@list)});
ok('RED', $menu->status_fgcolor('RED'));
ok('GREEN', $menu->status_bgcolor('GREEN'));
ok('RIGHT', $menu->status_align('RIGHT'));
ok(1, $menu->status_fill(1));
ok(0, $menu->status_frame(0));
@list = ('BLINK');
ok(@list, @{$menu->status_frame_style(\@list)});
ok('RED', $menu->status_frame_fgcolor('RED'));
ok('GREEN', $menu->status_frame_bgcolor('GREEN'));
ok('Press a key: ', $menu->prompt('Press a key: '));
@list = ('BOLD');
ok(@list, @{$menu->prompt_style(\@list)});
ok('RED', $menu->prompt_fgcolor('RED'));
ok('GREEN', $menu->prompt_bgcolor('GREEN'));
ok('LEFT', $menu->prompt_align('LEFT'));
ok(1, $menu->prompt_fill(1));
ok(1, $menu->prompt_frame(1));
@list = ('BOLD');
ok(@list, @{$menu->prompt_frame_style(\@list)});
ok('RED', $menu->prompt_frame_fgcolor('RED'));
ok('GREEN', $menu->prompt_frame_bgcolor('GREEN'));

#Test methods than are not interactive and do not print directly to STDOUT
@list = ('UP', 'PGUP');
$menu->up_keys(\@list);
ok(1, $menu->is_up_key('UP'));
@list = ('DOWN', 'PGDN');
$menu->down_keys(\@list);
ok(1, $menu->is_down_key('DOWN'));
@list = ('F1', '?');
$menu->help_keys(\@list);
ok(1, $menu->is_help_key('F1'));
@list = ('q', 'Q', 'CTRL-c');
$menu->exit_keys(\@list);
ok(1, $menu->is_exit_key('CTRL-c'));
@list = ('SPACE', 'ENTER');
$menu->selection_keys(\@list);
ok(1, $menu->is_selection_key('ENTER'));
@list = (['1', 'First menu item', sub { return 1 }],
         ['2', 'Second menu item'],
         ['3', '', sub { return 1 }]);
$menu->items(\@list);
ok(3, $menu->is_shortcut('3'));
ok((1, 2, 3), @{$menu->shortcuts()});
ok(3, $menu->item_count());

