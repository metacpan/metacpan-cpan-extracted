#!/usr/bin/perl
use strict;
use warnings;

use Glib ':constants';
use Gtk2 -init;

my $window_width = 600;
my $window_height = 400;

use Encode;
use File::Basename;
use Parse::Win32Registry 0.60 qw(:REG_);

binmode(STDOUT, ':utf8');

my $script_name = basename $0;

### LIST VIEW FOR BLOCK

use constant {
    COLUMN_BLOCK_OFFSET => 0,
    COLUMN_BLOCK_LENGTH => 1,
    COLUMN_BLOCK_TAG => 2,
    COLUMN_BLOCK_OBJECT => 3,
};

my $block_store = Gtk2::ListStore->new(
    'Glib::String','Glib::String',  'Glib::String', 'Glib::Scalar',
);

my $block_view = Gtk2::TreeView->new($block_store);

my $hbin_column1 = Gtk2::TreeViewColumn->new_with_attributes(
    'Block', Gtk2::CellRendererText->new,
    'text', COLUMN_BLOCK_OFFSET,
);
$block_view->append_column($hbin_column1);
$hbin_column1->set_resizable(TRUE);

my $hbin_column2 = Gtk2::TreeViewColumn->new_with_attributes(
    'Length', Gtk2::CellRendererText->new,
    'text', COLUMN_BLOCK_LENGTH,
);
$block_view->append_column($hbin_column2);
$hbin_column2->set_resizable(TRUE);

my $hbin_column3 = Gtk2::TreeViewColumn->new_with_attributes(
    'Tag', Gtk2::CellRendererText->new,
    'text', COLUMN_BLOCK_TAG,
);
$block_view->append_column($hbin_column3);
$hbin_column3->set_resizable(TRUE);

my $block_selection = $block_view->get_selection;
$block_selection->set_mode('browse');
$block_selection->signal_connect('changed' => \&block_selection_changed);

my $scrolled_block_view = Gtk2::ScrolledWindow->new;
$scrolled_block_view->set_policy('automatic', 'automatic');
$scrolled_block_view->set_shadow_type('in');
$scrolled_block_view->add($block_view);

### LIST VIEW FOR ENTRY

use constant {
    COLUMN_ENTRY_OFFSET => 0,
    COLUMN_ENTRY_LENGTH => 1,
    COLUMN_ENTRY_TAG => 2,
    COLUMN_ENTRY_NAME => 3,
    COLUMN_ENTRY_ALLOC => 4,
    COLUMN_ENTRY_COLOR => 5,
    COLUMN_ENTRY_OBJECT => 6,
};

my $entry_store = Gtk2::ListStore->new(
    'Glib::String', 'Glib::String', 'Glib::String',
    'Glib::String', 'Glib::String', 'Glib::String',
    'Glib::Scalar', 'Glib::String',
);

my $entry_view = Gtk2::TreeView->new($entry_store);

my $entry_column0 = Gtk2::TreeViewColumn->new_with_attributes(
    'Entry', my $entry_cell0 = Gtk2::CellRendererText->new,
    'text', COLUMN_ENTRY_OFFSET,
    'background', COLUMN_ENTRY_COLOR,
);
$entry_view->append_column($entry_column0);
$entry_column0->set_resizable(TRUE);

my $entry_column1 = Gtk2::TreeViewColumn->new_with_attributes(
    'Length', Gtk2::CellRendererText->new,
    'text', COLUMN_ENTRY_LENGTH,
    'background', COLUMN_ENTRY_COLOR,
);
$entry_view->append_column($entry_column1);
$entry_column1->set_resizable(TRUE);

my $entry_column2 = Gtk2::TreeViewColumn->new_with_attributes(
    'Alloc.', Gtk2::CellRendererText->new,
    'text', COLUMN_ENTRY_ALLOC,
    'background', COLUMN_ENTRY_COLOR,
);
$entry_view->append_column($entry_column2);
$entry_column2->set_resizable(TRUE);

my $entry_column3 = Gtk2::TreeViewColumn->new_with_attributes(
    'Tag', Gtk2::CellRendererText->new,
    'text', COLUMN_ENTRY_TAG,
    'background', COLUMN_ENTRY_COLOR,
);
$entry_view->append_column($entry_column3);
$entry_column3->set_resizable(TRUE);

my $entry_column4 = Gtk2::TreeViewColumn->new_with_attributes(
    'Name', Gtk2::CellRendererText->new,
    'text', COLUMN_ENTRY_NAME,
    'background', COLUMN_ENTRY_COLOR,
);
$entry_view->append_column($entry_column4);
$entry_column4->set_resizable(TRUE);

my $entry_selection = $entry_view->get_selection;
$entry_selection->set_mode('browse');
$entry_selection->signal_connect('changed' => \&entry_selection_changed);

my $scrolled_entry_view = Gtk2::ScrolledWindow->new;
$scrolled_entry_view->set_policy('automatic', 'automatic');
$scrolled_entry_view->set_shadow_type('in');
$scrolled_entry_view->add($entry_view);

### TEXT VIEW

my $text_view = Gtk2::TextView->new;
$text_view->set_editable(FALSE);
$text_view->modify_font(Gtk2::Pango::FontDescription->from_string('monospace'));

my $text_buffer = $text_view->get_buffer;

my $scrolled_text_view = Gtk2::ScrolledWindow->new;
$scrolled_text_view->set_policy('automatic', 'automatic');
$scrolled_text_view->set_shadow_type('in');
$scrolled_text_view->add($text_view);

### HPANED

my $hpaned = Gtk2::HPaned->new;
$hpaned->pack1($scrolled_block_view, FALSE, FALSE);
$hpaned->pack2($scrolled_entry_view, TRUE, FALSE);
$hpaned->set_position($window_width / 3);

### VPANED

my $vpaned = Gtk2::VPaned->new;
$vpaned->pack1($hpaned, FALSE, FALSE);
$vpaned->pack2($scrolled_text_view, FALSE, FALSE);

### UIMANAGER

my $uimanager = Gtk2::UIManager->new;

my @actions = (
    # name, stock id, label
    ['FileMenu', undef, '_File'],
    ['SearchMenu', undef, '_Search'],
    ['ViewMenu', undef, '_View'],
    ['HelpMenu', undef, '_Help'],
    # name, stock-id, label, accelerator, tooltip, callback
    ['Open', 'gtk-open', '_Open...', '<control>O', undef, \&open_file],
    ['Close', 'gtk-close', '_Close', '<control>W', undef, \&close_file],
    ['Quit', 'gtk-quit', '_Quit', '<control>Q', undef, \&quit],
    ['Find', 'gtk-find', '_Find...', '<control>F', undef, \&find],
    ['FindNext', undef, 'Find _Next', '<control>G', undef, \&find_next],
    ['FindNext2', undef, undef, 'F3', undef, \&find_next],
    ['GoTo', 'gtk-index', '_Go To Offset...', '<control>I', undef, \&go_to_offset],
    ['About', 'gtk-about', '_About...', undef, undef, \&about],
);

my $default_actions = Gtk2::ActionGroup->new('actions');
$default_actions->add_actions(\@actions, undef);

$uimanager->insert_action_group($default_actions, 0);

my $ui_info = <<END_OF_UI;
<ui>
    <menubar name='MenuBar'>
        <menu action='FileMenu'>
            <menuitem action='Open'/>
            <menuitem action='Close'/>
            <separator/>
            <menuitem action='Quit'/>
        </menu>
        <menu action='SearchMenu'>
            <menuitem action='Find'/>
            <menuitem action='FindNext'/>
            <separator/>
            <menuitem action='GoTo'/>
        </menu>
        <menu action='HelpMenu'>
            <menuitem action='About'/>
        </menu>
    </menubar>
    <accelerator action='FindNext2'/>
</ui>
END_OF_UI

$uimanager->add_ui_from_string($ui_info);

my $menubar = $uimanager->get_widget('/MenuBar');

### STATUSBAR

my $statusbar = Gtk2::Statusbar->new;

### VBOX

my $main_vbox = Gtk2::VBox->new(FALSE, 0);
$main_vbox->pack_start($menubar, FALSE, FALSE, 0);
$main_vbox->pack_start($vpaned, TRUE, TRUE, 0);
$main_vbox->pack_start($statusbar, FALSE, FALSE, 0);

### WINDOW

my $window = Gtk2::Window->new;
$window->set_default_size($window_width, $window_height);
$window->set_position('center');
$window->signal_connect(destroy => sub { Gtk2->main_quit });
$window->add($main_vbox);
$window->add_accel_group($uimanager->get_accel_group);
$window->set_title($script_name);
$window->show_all;

### GLOBALS

my $registry;

my $last_dir;

my $find_param = '';
my $find_iter;

my $filename = shift;
if (defined $filename && -r $filename) {
    load_file($filename);
}

Gtk2->main;

###############################################################################

sub load_entries {
    my $block = shift;

    $entry_store->clear;

    my $entry_iter = $block->get_entry_iterator;
    while (my $entry = $entry_iter->get_next) {
        my $iter = $entry_store->append;

        my $tag = $entry->get_tag;
        my $offset = $entry->get_offset;

        # colorize each row according to its tag
        my $color;
        if ($tag eq 'nk' || $tag eq 'rgkn key' || $tag eq 'rgdb key') {
            $color = '#ffb0b0'; # red
        }
        elsif ($tag eq 'sk') {
            $color = '#b0ffff'; # cyan
        }
        elsif ($tag eq 'vk' || $tag eq 'rgdb value') {
            $color = '#b0ffb0'; # green
        }
        elsif ($tag eq 'lh' || $tag eq 'lf' || $tag eq 'li' || $tag eq 'ri') {
            $color = '#ffb0ff'; # magenta
        }
        else {
            $color = '#f0f0f0'; # grey
        }

        my $name = $entry->can('get_name') ? $entry->get_name : '';
        $name =~ s/\0/[NUL]/g;
        $entry_store->set($iter,
            COLUMN_ENTRY_OFFSET, sprintf("0x%x", $offset),
            COLUMN_ENTRY_LENGTH, sprintf("0x%x", $entry->get_length),
            COLUMN_ENTRY_TAG, $tag,
            COLUMN_ENTRY_ALLOC, $entry->is_allocated,
            COLUMN_ENTRY_NAME, $name,
            COLUMN_ENTRY_COLOR, $color,
            COLUMN_ENTRY_OBJECT, $entry);
    }
}

sub block_selection_changed {
    my ($model, $iter) = $block_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $block = $model->get($iter, COLUMN_BLOCK_OBJECT);

    my $parse_info = $block->parse_info;
    my $str = $parse_info . "\n"
            . $block->unparsed;
    $text_buffer->set_text($str);

    my $status = sprintf "Block Offset: 0x%x", $block->get_offset;
    $statusbar->pop(0);
    $statusbar->push(0, $status);

    load_entries($block);
}

sub entry_selection_changed {
    my ($model, $iter) = $entry_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $entry = $model->get($iter, COLUMN_ENTRY_OBJECT);

    my $parse_info = $entry->parse_info;
    $parse_info =~ s/\0/[NUL]/g;
    my $str = $parse_info . "\n"
            . $entry->unparsed;
    $text_buffer->set_text($str);

    my $status = sprintf "Entry Offset: 0x%x", $entry->get_offset;
    $statusbar->pop(0);
    $statusbar->push(0, $status);
}

sub show_message {
    my $type = shift;
    my $message = shift;

    my $dialog = Gtk2::MessageDialog->new(
        $window,
        'destroy-with-parent',
        $type,
        'ok',
        $message,
    );
    $dialog->set_title(ucfirst $type);
    $dialog->run;
    $dialog->destroy;
}

sub load_file {
    my $filename = shift;

    my ($name, $path) = fileparse($filename);

    close_file();

    if (!-r $filename) {
        show_message('error', "Unable to open '$name'.");
    }
    elsif ($registry = Parse::Win32Registry->new($filename)) {
        if (my $root_key = $registry->get_root_key) {
            $window->set_title("$name - $script_name");

            my $block_iter = $registry->get_block_iterator;
            while (my $block = $block_iter->get_next) {
                my $iter = $block_store->append;
                $block_store->set($iter,
                    COLUMN_BLOCK_OFFSET, sprintf("0x%x", $block->{_offset}),
                    COLUMN_BLOCK_LENGTH, sprintf("0x%x", $block->get_length),
                    COLUMN_BLOCK_TAG, $block->get_tag,
                    COLUMN_BLOCK_OBJECT, $block);
            }
        }
    }
    else {
        show_message('error', "'$name' is not a registry file.");
    }
}

sub choose_file {
    my ($title, $type, $suggested_name) = @_;

    my $file_chooser = Gtk2::FileChooserDialog->new(
        $title,
        undef,
        $type,
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    if ($type eq 'save') {
        $file_chooser->set_current_name($suggested_name);
    }
    if (defined $last_dir) {
        $file_chooser->set_current_folder($last_dir);
    }
    my $response = $file_chooser->run;

    my $filename;
    if ($response eq 'ok') {
        $filename = $file_chooser->get_filename;
    }
    $last_dir = $file_chooser->get_current_folder;
    $file_chooser->destroy;
    return $filename;
}

sub open_file {
    my $filename = choose_file('Select Registry File', 'open');
    if (defined $filename) {
        load_file($filename);
    }
}

sub close_file {
    $block_store->clear;
    $entry_store->clear;
    $registry = undef;
    $text_buffer->set_text('');
    $statusbar->pop(0);
}

sub quit {
    $window->destroy;
}

sub about {
    Gtk2->show_about_dialog(undef,
        'program-name' => $script_name,
        'version' => $Parse::Win32Registry::VERSION,
        'copyright' => 'Copyright (c) 2009-2012 James Macfarlane',
        'comments' => 'GTK2 Registry Scope for the Parse::Win32Registry module',
    );
}

sub go_to_block {
    my ($offset) = @_;

    my $iter = $block_store->get_iter_first;
    while (defined $iter) {
        my $block = $block_store->get($iter, COLUMN_BLOCK_OBJECT);
        my $block_start = $block->get_offset;
        my $block_end = $block_start + $block->get_length;
        if ($offset >= $block_start && $offset < $block_end) {
            my $tree_path = $block_store->get_path($iter);
            $block_view->expand_to_path($tree_path);
            $block_view->scroll_to_cell($tree_path);
            $block_view->set_cursor($tree_path);
            $window->set_focus($block_view);
            return;
        }
        $iter = $block_store->iter_next($iter);
    }
}

sub go_to_entry {
    my ($offset) = @_;

    my $iter = $entry_store->get_iter_first;
    while (defined $iter) {
        my $entry = $entry_store->get($iter, COLUMN_ENTRY_OBJECT);
        my $entry_start = $entry->get_offset;
        my $entry_end = $entry_start + $entry->get_length;
        if ($offset >= $entry_start && $offset < $entry_end) {
            my $tree_path = $entry_store->get_path($iter);
            $entry_view->expand_to_path($tree_path);
            $entry_view->scroll_to_cell($tree_path);
            $entry_view->set_cursor($tree_path);
            $window->set_focus($entry_view);
            return;
        }
        $iter = $entry_store->iter_next($iter);
    }
}

sub find_next {
    if (!defined $find_param || !defined $find_iter) {
        return;
    }

    # Build find next dialog
    my $label = Gtk2::Label->new;
    $label->set_text("Searching registry entries...");
    my $dialog = Gtk2::Dialog->new('Find',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
    );
    $dialog->vbox->pack_start($label, TRUE, TRUE, 5);
    $dialog->set_default_response('cancel');
    $dialog->show_all;

    my $id = Glib::Idle->add(sub {
        my $entry = $find_iter->get_next;
        if (defined $entry) {
            my $found = 0;
            if (index(lc $entry->get_raw_bytes, lc $find_param) > -1) {
                $found = 1;
            }
            else {
                my $uni_find_param = encode("UCS-2LE", $find_param);
                if (index(lc $entry->get_raw_bytes, lc $uni_find_param) > -1) {
                    $found = 1;
                }
            }
            if ($found) {
                go_to_block($entry->get_offset);
                go_to_entry($entry->get_offset);

                $dialog->response(50);
                return FALSE;
            }

            return TRUE; # continue searching...
        }

        $dialog->response('ok');
        return FALSE;
    });

    my $response = $dialog->run;
    $dialog->destroy;

    if ($response eq 'cancel' || $response eq 'delete-event') {
        Glib::Source->remove($id);
    }
    elsif ($response eq 'ok') {
        show_message('info', 'Finished searching.');
    }
}

sub find {
    return if !defined $registry;

    my $label = Gtk2::Label->new('Enter text to search for:');
    $label->set_alignment(0, 0);
    my $entry = Gtk2::Entry->new;
    $entry->set_text($find_param);
    $entry->set_activates_default(TRUE);
    my $dialog = Gtk2::Dialog->new('Find',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    $dialog->vbox->set_spacing(5);
    $dialog->vbox->pack_start($label, FALSE, TRUE, 0);
    $dialog->vbox->pack_start($entry, FALSE, TRUE, 0);
    $dialog->set_default_response('ok');
    $dialog->show_all;

    my $response = $dialog->run;
    if ($response eq 'ok') {
        $find_param = $entry->get_text;
        $dialog->destroy;
        $find_iter = undef;
        if ($find_param ne '') {
            $find_iter = $registry->get_entry_iterator;
            find_next;
        }
    }
    else {
        $dialog->destroy;
    }
}

sub go_to_offset {
    return if !defined $registry;

    my $entry = Gtk2::Entry->new;
    $entry->set_activates_default(TRUE);
    my $dialog = Gtk2::Dialog->new('Go To Offset',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    $dialog->vbox->pack_start($entry, TRUE, TRUE, 5);
    $dialog->set_default_response('ok');
    $dialog->show_all;

    $entry->prepend_text("0x");
    $entry->set_position(-1);

    my $response = $dialog->run;
    my $answer = $entry->get_text;
    $dialog->destroy;

    if ($response ne 'ok') {
        return;
    }

    my $offset;
    eval {
        if ($answer =~ m/^\s*0x[\da-fA-F]+\s*$/ || $answer =~ m/^\s*\d+\s*$/) {
            $offset = int(eval $answer);
        }
    };

    if (defined $offset && $offset < $registry->get_length) {
        go_to_block($offset);
        go_to_entry($offset);
    }
}
