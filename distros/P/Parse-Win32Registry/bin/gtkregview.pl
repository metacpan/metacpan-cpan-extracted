#!/usr/bin/perl
use strict;
use warnings;

use Glib ':constants';
use Gtk2 -init;

my $window_width = 600;
my $window_height = 400;

use File::Basename;
use File::Spec;
use Parse::Win32Registry 0.51 qw(hexdump);

binmode(STDOUT, ':utf8');

my $script_name = basename $0;

### LIST VIEW

my $list_store = Gtk2::ListStore->new(
    'Glib::String', 'Glib::String', 'Glib::String', 'Glib::Scalar',
);
# 0 = list store name (value name)
# 1 = list store type (value timestamp)
# 2 = list store data (value class name)
# 3 = list store value (value object)

my $list_view = Gtk2::TreeView->new($list_store);

my @list_column_names = qw(Name Type Data);
for (my $col = 0; $col < @list_column_names; $col++) {
    my $text_cell = Gtk2::CellRendererText->new;
    if ($col == 2) {
        $text_cell->set('ellipsize', 'end');
    }
    my $column = Gtk2::TreeViewColumn->new_with_attributes(
        $list_column_names[$col],
        $text_cell,
        'text', $col);
    $list_view->append_column($column);
    $column->set_resizable(TRUE);
    $list_store->set_sort_func($col, sub {
        my ($model, $itera, $iterb, $col) = @_;
        my $a = $model->get($itera, $col);
        my $b = $model->get($iterb, $col);
        $a = '' if !defined $a;
        $b = '' if !defined $b;
        return $a cmp $b;
    }, $col);
    $column->set_sort_column_id($col);
}
$list_view->set_rules_hint(TRUE);

my $list_selection = $list_view->get_selection;
$list_selection->set_mode('browse');
$list_selection->signal_connect('changed' => \&value_selected);

my $scrolled_list_view = Gtk2::ScrolledWindow->new;
$scrolled_list_view->set_policy('automatic', 'automatic');
$scrolled_list_view->set_shadow_type('in');
$scrolled_list_view->add($list_view);

### TEXT VIEW

my $text_view = Gtk2::TextView->new;
$text_view->set_editable(FALSE);
$text_view->modify_font(Gtk2::Pango::FontDescription->from_string('monospace'));

my $text_buffer = $text_view->get_buffer;

my $scrolled_text_view = Gtk2::ScrolledWindow->new;
$scrolled_text_view->set_policy('automatic', 'automatic');
$scrolled_text_view->set_shadow_type('in');
$scrolled_text_view->add($text_view);

### VPANED

my $vpaned = Gtk2::VPaned->new;
$vpaned->pack1($scrolled_list_view, FALSE, FALSE);
$vpaned->pack2($scrolled_text_view, FALSE, FALSE);

### TREE VIEW

my $tree_store = Gtk2::TreeStore->new(
    'Glib::String', 'Glib::String', 'Glib::String', 'Glib::Scalar',
);
# 0 = tree store name (key name)
# 1 = tree store timestamp (key timestamp)
# 2 = tree store class name (key class name)
# 3 = tree store key (key object)

my $tree_view = Gtk2::TreeView->new($tree_store);

my @tree_columns;
my @tree_column_names = ('Name', 'Timestamp', 'Class Name');
for (my $col = 0; $col < @tree_column_names; $col++) {
    my $column = Gtk2::TreeViewColumn->new;
    if ($col == 0) {
        my $icon_cell = Gtk2::CellRendererPixbuf->new;
        $icon_cell->set('stock-id', 'gtk-directory');
        $column->pack_start($icon_cell, FALSE);
    }
    my $text_cell = Gtk2::CellRendererText->new;
    $column->pack_start($text_cell, TRUE);
    $column->set_attributes($text_cell, 'text', $col);
    $column->set_title($tree_column_names[$col]);
    $column->set_resizable(TRUE);
    $tree_view->append_column($column);
    push @tree_columns, $column;
    $tree_store->set_sort_func($col, sub {
        my ($model, $itera, $iterb, $col) = @_;
        my $a = $model->get($itera, $col);
        my $b = $model->get($iterb, $col);
        $a = '' if !defined $a;
        $b = '' if !defined $b;
        return $a cmp $b;
    }, $col);
    $column->set_sort_column_id($col);
}
$tree_view->set_rules_hint(TRUE);

# row-expanded when row is expanded (e.g. after user clicks on arrow)
$tree_view->signal_connect('row-expanded' => \&expand_row);
$tree_view->signal_connect('row-collapsed' => \&collapse_row);
# row-activated when user double clicks on row
$tree_view->signal_connect('row-activated' => \&activate_row);

my $tree_selection = $tree_view->get_selection;
$tree_selection->set_mode('browse');
$tree_selection->signal_connect('changed' => \&key_selected);

my $scrolled_tree_view = Gtk2::ScrolledWindow->new;
$scrolled_tree_view->set_policy('automatic', 'automatic');
$scrolled_tree_view->set_shadow_type('in');
$scrolled_tree_view->add($tree_view);

### HPANED

my $hpaned = Gtk2::HPaned->new;
$hpaned->pack1($scrolled_tree_view, FALSE, FALSE);
$hpaned->pack2($vpaned, TRUE, FALSE);

$hpaned->set_position($window_width * 0.3);

### MENU

use Gtk2::Gdk::Keysyms;

my $menubar = Gtk2::MenuBar->new;

my $accel_group = Gtk2::AccelGroup->new;

# File Menu
my $open_menuitem = Gtk2::MenuItem->new('_Open...');
$open_menuitem->signal_connect('activate' => \&open_file);
$open_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{O}, ['control-mask'], ['visible', 'locked']);
my $close_menuitem = Gtk2::MenuItem->new('_Close');
$close_menuitem->signal_connect('activate' => \&close_file);
$close_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{W}, ['control-mask'], ['visible', 'locked']);
my $quit_menuitem = Gtk2::MenuItem->new('_Quit');
$quit_menuitem->signal_connect('activate' => \&quit);
$quit_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{Q}, ['control-mask'], ['visible', 'locked']);

my $file_menu = Gtk2::Menu->new;
$file_menu->append($open_menuitem);
$file_menu->append($close_menuitem);
$file_menu->append(Gtk2::SeparatorMenuItem->new);
$file_menu->append($quit_menuitem);
$file_menu->set_accel_group($accel_group);

# Edit Menu
my $copy_menuitem = Gtk2::MenuItem->new('_Copy Key Path');
$copy_menuitem->signal_connect('activate' => \&copy_key_path);
$copy_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{C}, ['control-mask'], ['visible', 'locked']);

my $edit_menu = Gtk2::Menu->new;
$edit_menu->append($copy_menuitem);

# Search Menu
my $find_menuitem = Gtk2::MenuItem->new('_Find...');
$find_menuitem->signal_connect('activate' => \&find);
$find_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{F}, ['control-mask'], ['visible', 'locked']);
my $find_next_menuitem = Gtk2::MenuItem->new('Find _Next');
$find_next_menuitem->signal_connect('activate' => \&find_next);
$find_next_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{G}, ['control-mask'], ['visible', 'locked']);
$find_next_menuitem->add_accelerator('activate', $accel_group,
    $Gtk2::Gdk::Keysyms{F3}, [], ['visible', 'locked']);

my $search_menu = Gtk2::Menu->new;
$search_menu->append($find_menuitem);
$search_menu->append($find_next_menuitem);

# Help Menu
my $about_menuitem = Gtk2::MenuItem->new('_About...');
$about_menuitem->signal_connect('activate' => \&about);

my $help_menu = Gtk2::Menu->new;
$help_menu->append($about_menuitem);

# Menu Bar
my $file_menuitem = Gtk2::MenuItem->new('_File');
$file_menuitem->set_submenu($file_menu);
$menubar->append($file_menuitem);

my $edit_menuitem = Gtk2::MenuItem->new('_Edit');
$edit_menuitem->set_submenu($edit_menu);
$menubar->append($edit_menuitem);

my $search_menuitem = Gtk2::MenuItem->new('_Search');
$search_menuitem->set_submenu($search_menu);
$menubar->append($search_menuitem);

my $help_menuitem = Gtk2::MenuItem->new('_Help');
$help_menuitem->set_submenu($help_menu);
$menubar->append($help_menuitem);

### STATUSBAR

my $statusbar = Gtk2::Statusbar->new;

### VBOX

my $main_vbox = Gtk2::VBox->new(FALSE, 0);
$main_vbox->pack_start($menubar, FALSE, FALSE, 0);
$main_vbox->pack_start($hpaned, TRUE, TRUE, 0);
$main_vbox->pack_start($statusbar, FALSE, FALSE, 0);

### WINDOW

my $window = Gtk2::Window->new;
$window->set_default_size($window_width, $window_height);
$window->set_position('center');
$window->signal_connect(destroy => sub { Gtk2->main_quit });
$window->add($main_vbox);
$window->add_accel_group($accel_group);
$window->set_title($script_name);
$window->show_all;

### GLOBALS

my $search_keys = TRUE;
my $search_values = TRUE;
my $search_selected = 0;
my $find_param = '';
my $find_iter;

my $last_dir;

my $filename = shift;
if (defined $filename && -r $filename) {
    $filename = File::Spec->rel2abs($filename);
    load_file($filename);
}

Gtk2->main;

###############################################################################

sub key_selected {
    my ($model, $iter) = $tree_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $key = $model->get($iter, 3);

    # Fill list with the values of this key
    $list_store->clear;
    my @values = $key->get_list_of_values;
    foreach my $value (@values) {
        my $name = $value->get_name;
        $name = '(Default)' if $name eq '';
        $name =~ s/\0/[NUL]/g;
        my $type = $value->get_type_as_string;
        my $data = $value->get_data_as_string;
        $data =~ s/\0/[NUL]/g;
        # Abbreviate very long data to avoid a performance hit
        # from loading large strings into the model
        $data = substr($data, 0, 500);
        my $iter = $list_store->append;
        $list_store->set($iter,
            0, $name,
            1, $type,
            2, $data,
            3, $value);
    }

    my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_PRIMARY);
    $clipboard->set_text($key->get_path);

    # Display key information:
    my $str = '';
    my $security = $key->get_security;
    if (defined $security) {
        my $sd = $security->get_security_descriptor;
        $str .= $sd->as_stanza;
    }

    my $text_buffer = $text_view->get_buffer;
    $text_buffer->set_text($str);
    $statusbar->pop(0);
    my $key_path = $key->get_path;
    $key_path =~ s/\0/[NUL]/g;
    $statusbar->push(0, $key_path);
}

sub value_selected {
    my ($model, $iter) = $list_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $value = $model->get($iter, 3);

    my $name = $value->get_name;
    $name = '(Default)' if $name eq '';
    my $type = $value->get_type_as_string;

    my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_PRIMARY);
    $clipboard->set_text($name);

    # Display value information:
    my $str = hexdump($value->get_raw_data);

    my $text_buffer = $text_view->get_buffer;
    $text_buffer->set_text($str);
}

sub add_root {
    my ($key, $model, undef) = @_;
    my $iter = $model->append(undef);
    my $name = $key->get_name;
    $name =~ s/\0/[NUL]/g;
    my $timestamp = defined($key->get_timestamp)
                  ? $key->get_timestamp_as_string
                  : '';
    my $class_name = defined($key->get_class_name)
                   ? $key->get_class_name
                   : '';
    $class_name =~ s/\0/[NUL]/g;
    $model->set($iter,
        0, $name,
        1, $timestamp,
        2, $class_name,
        3, $key,
    );
    my $dummy = $model->append($iter);
}

sub add_children {
    my ($key, $model, $iter) = @_;
    # my @subkeys = defined $iter ? $key->get_list_of_subkeys : ($key);
    my @subkeys = $key->get_list_of_subkeys;
    foreach my $subkey (@subkeys) {
        my $child_iter = $model->append($iter);
        my $name = $subkey->get_name;
        $name =~ s/\0/[NUL]/g;
        my $timestamp = defined($subkey->get_timestamp)
                      ? $subkey->get_timestamp_as_string
                      : '';
        my $class_name = defined($subkey->get_class_name)
                       ? $subkey->get_class_name
                       : '';
        $class_name =~ s/\0/[NUL]/g;
        $model->set($child_iter,
            0, $name,
            1, $timestamp,
            2, $class_name,
            3, $subkey,
        );
        my $dummy = $model->append($child_iter); ### load gradually
        #add_children($subkey, $model, $child_iter); ### load everything
    }
}

sub expand_row {
    my ($view, $iter, $path) = @_;

    my $model = $view->get_model;
    my $key = $model->get($iter, 3);
    my $first_child_iter = $model->iter_nth_child($iter, 0);
    if (!defined $model->get($first_child_iter, 0)) {
        add_children($key, $model, $iter);
        $model->remove($first_child_iter);
    }
}

sub collapse_row {
    my ($view, $iter, $path) = @_;

    return; # uncomment to remove children when collapsing

    my $model = $view->get_model;
    my $child_iter = $model->iter_nth_child($iter, 0);
    if (!defined $child_iter) {
        # this key has no children
        return;
    }

    my @child_iters = ();
    while (defined $child_iter) {
        if (defined $model->get($child_iter, 0)) {
            push @child_iters, $child_iter;
        }
        $child_iter = $tree_store->iter_next($child_iter);
    }
    foreach my $child_iter (@child_iters) {
        $tree_store->remove($child_iter);
    }
    my $dummy = $tree_store->append($iter);
}

sub activate_row {
    my ($view, $path, $column) = @_;
    if ($view->row_expanded($path)) {
        $view->collapse_row($path);
    }
    else {
        # only rows with children will actually be expanded
        $view->expand_row($path, FALSE);
    }
}

sub load_file {
    my $filename = shift;

    my ($name, $path) = fileparse($filename);

    close_file();

    if (!-r $filename) {
        show_message('error', "Unable to open '$name'.");
    }
    elsif (my $registry = Parse::Win32Registry->new($filename)) {
        if (my $root_key = $registry->get_root_key) {
            add_root($root_key, $tree_store, undef);
            $window->set_title("$name - $script_name");
            if (defined $root_key->get_timestamp) {
                $tree_columns[1]->set_visible(TRUE);
                $tree_columns[2]->set_visible(TRUE);
            }
            else {
                $tree_columns[1]->set_visible(FALSE);
                $tree_columns[2]->set_visible(FALSE);
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
    if ($filename) {
        load_file($filename);
    }
}

sub close_file {
    $tree_store->clear;
    $list_store->clear;
    $text_buffer->set_text('');
    $find_param = '';
    $find_iter = undef;
    $statusbar->pop(0);
}

sub quit {
    $window->destroy;
}

sub about {
    Gtk2->show_about_dialog(undef,
        'program-name' => $script_name,
        'version' => $Parse::Win32Registry::VERSION,
        'copyright' => 'Copyright (c) 2008-2012 James Macfarlane',
        'comments' => 'GTK2 Registry Viewer for the Parse::Win32Registry module',
    );
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

sub copy_key_path {
    my $tree_iter = $tree_selection->get_selected;
    my $clip = '';
    if (defined $tree_iter) {
        my $key = $tree_store->get($tree_iter, 3);
        $clip = $key->get_path;
    }
    my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_CLIPBOARD);
    $clipboard->set_text($clip);
}

sub go_to_value {
    my $value_name = shift;

    my $iter = $list_store->get_iter_first;
    while (defined $iter) {
        my $name = $list_store->get($iter, 0);
        my $value = $list_store->get($iter, 3);

        if ($value_name eq $value->get_name) {
            my $tree_path = $list_store->get_path($iter);
            $list_view->expand_to_path($tree_path);
            $list_view->scroll_to_cell($tree_path);
            $list_view->set_cursor($tree_path);
            $window->set_focus($list_view);
            return;
        }

        $iter = $list_store->iter_next($iter);
    }
}

sub find_matching_child_iter {
    my ($iter, $subkey_name) = @_;

    my $child_iter = $tree_store->iter_nth_child($iter, 0);
    if (!defined $child_iter) {
        # iter has already been expanded and has no children
        return;
    }

    # Check iter's children are real
    if (!defined $tree_store->get($child_iter, 0)) {
        my $key = $tree_store->get($iter, 3);
        add_children($key, $tree_store, $iter);
        $tree_store->remove($child_iter);
        # (Need to refetch the first child iter after removing it.)
        $child_iter = $tree_store->iter_nth_child($iter, 0);
    }

    while (defined $child_iter) {
        my $child_key = $tree_store->get($child_iter, 3);

        # $tree_store->get($child_iter, 0) contains the displayed name,
        # $child_key->get_name is the actual name
        if ($child_key->get_name eq $subkey_name) {
            return $child_iter; # match found
        }
        $child_iter = $tree_store->iter_next($child_iter);
    }
    return; # no match found
}

sub go_to_subkey {
    my $subkey_path = shift;

    my @path_components = index($subkey_path, "\\") == -1
                        ? ($subkey_path)
                        : split(/\\/, $subkey_path, -1);

    my $iter = $tree_store->get_iter_first;
    return if !defined $iter; # no registry loaded

    while (defined(my $subkey_name = shift @path_components)) {
        $iter = find_matching_child_iter($iter, $subkey_name);
        if (!defined $iter) {
            return; # subkey cannot be found in/added to the tree store
        }

        if (@path_components == 0) {
            my $parent_iter = $tree_store->iter_parent($iter);
            my $parent_path = $tree_store->get_path($parent_iter);
            $tree_view->expand_to_path($parent_path);
            my $tree_path = $tree_store->get_path($iter);
            $tree_view->scroll_to_cell($tree_path);
            $tree_view->set_cursor($tree_path);
            $window->set_focus($tree_view);
            return; # skip remaining search
        }
    }
}

sub get_search_message {
    my $message;
    if ($search_keys && $search_values) {
        $message = "Searching registry keys and values...";
    }
    elsif ($search_keys) {
        $message = "Searching registry keys...";
    }
    elsif ($search_values) {
        $message = "Searching registry values...";
    }
    return $message;
}

sub find_next {
    if (!defined $find_param || !defined $find_iter) {
        return;
    }

    my $label = Gtk2::Label->new;
    $label->set_text(get_search_message);
    my $dialog = Gtk2::Dialog->new('Find',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
    );
    $dialog->vbox->pack_start($label, TRUE, TRUE, 5);
    $dialog->set_default_response('cancel');
    $dialog->show_all;

    my $id = Glib::Idle->add(sub {
        my ($key, $value) = $find_iter->get_next;

        if (!defined $key) {
            $dialog->response('ok');
            return FALSE; # stop searching
        }

        # Remove root key name to get subkey path
        my $subkey_path = (split(/\\/, $key->get_path, 2))[1];

        if (!defined $subkey_path) {
            # go_to_subkey locates keys based on the subkey path
            # and does not support going to the root key.
            # Therefore if the subkey path is not defined,
            # the subtree iterator has returned the root key,
            # so searching it should be skipped.
            return TRUE; # continue searching
        }

        # Check value (if defined) for a match
        if (defined $value) {
            if ($search_values) {
                my $value_name = $value->get_name;
                if (index(lc $value_name, lc $find_param) >= 0) {
                    go_to_subkey($subkey_path);
                    go_to_value($value_name);
                    $dialog->response(50);
                    return FALSE; # stop searching
                }
            }
            return TRUE; # continue searching
        }

        # Check key for a match
        if ($search_keys) {
            my $key_name = $key->get_name;
            if (index(lc $key_name, lc $find_param) >= 0) {
                go_to_subkey($subkey_path);
                $dialog->response(50);
                return FALSE; # stop searching
            }
        }
        return TRUE; # continue searching
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
    return if !defined $tree_store->get_iter_first;

    my $root_iter = $tree_store->get_iter_first;
    return if !defined $root_iter;

    my $root_key = $tree_store->get($root_iter, 3);
    return if !defined $root_key;

    my $selected_key;
    my $iter = $tree_selection->get_selected;
    if (defined $iter) {
        $selected_key = $tree_store->get($iter, 3);
    }

    my $label = Gtk2::Label->new('Enter text to search for:');
    $label->set_alignment(0, 0);
    my $entry = Gtk2::Entry->new;
    $entry->set_text($find_param);
    $entry->set_activates_default(TRUE);
    my $check1 = Gtk2::CheckButton->new('Search _keys');
    $check1->set_active($search_keys);
    my $check2 = Gtk2::CheckButton->new('Search _values');
    $check2->set_active($search_values);
    $check1->signal_connect(toggled => sub {
        if (!$check1->get_active && !$check2->get_active) {
            $check2->set_active(TRUE);
        }
    });
    $check2->signal_connect(toggled => sub {
        if (!$check1->get_active && !$check2->get_active) {
            $check1->set_active(TRUE);
        }
    });
    my $frame = Gtk2::Frame->new('Start searching');
    my $vbox = Gtk2::VBox->new(FALSE, 0);
    $frame->add($vbox);
    my $radio1 = Gtk2::RadioButton->new(undef, 'from _root key');
    my $radio2 = Gtk2::RadioButton->new($radio1, 'from c_urrent key');
    if (!defined $selected_key) {
        $radio2->set_sensitive(FALSE);
    }
    elsif ($search_selected) {
        $radio2->set_active(TRUE);
    }
    $vbox->pack_start($radio1, TRUE, TRUE, 0);
    $vbox->pack_start($radio2, TRUE, TRUE, 0);

    my $dialog = Gtk2::Dialog->new('Find',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    $dialog->vbox->set_spacing(5);
    $dialog->vbox->pack_start($label, FALSE, TRUE, 0);
    $dialog->vbox->pack_start($entry, FALSE, TRUE, 0);
    $dialog->vbox->pack_start($check1, FALSE, TRUE, 0);
    $dialog->vbox->pack_start($check2, FALSE, TRUE, 0);
    $dialog->vbox->pack_start($frame, FALSE, TRUE, 0);
    $dialog->set_default_response('ok');
    $dialog->show_all;

    my $response = $dialog->run;
    if ($response eq 'ok') {
        $search_keys = $check1->get_active;
        $search_values = $check2->get_active;
        $search_selected = $radio2->get_active;
        $find_param = $entry->get_text;
        $dialog->destroy;
        $find_iter = undef;
        if ($find_param ne '') {
            $find_iter = $search_selected
                       ? $selected_key->get_subtree_iterator
                       : $root_key->get_subtree_iterator;
            find_next;
        }
    }
    else {
        $dialog->destroy;
    }
}
