#!/usr/bin/perl
use strict;
use warnings;

use Glib ':constants';
use Gtk2 -init;

my $window_width = 600;
my $window_height = 400;

use File::Basename;
use File::Spec;
use Parse::Win32Registry 0.51 qw( make_multiple_subtree_iterator
                                  make_multiple_subkey_iterator
                                  make_multiple_value_iterator
                                  compare_multiple_keys
                                  compare_multiple_values
                                  hexdump );

binmode(STDOUT, ':utf8');

my $script_name = basename $0;

### REGISTRY FILE STORE

use constant {
    REGCOL_FILENAME => 0,
    REGCOL_EMBEDDED_FILENAME => 1,
    REGCOL_TIMESTAMP => 2,
    REGCOL_DIRECTORY => 3,
    REGCOL_REGISTRY => 4,
};

my $registry_store = Gtk2::ListStore->new(
    'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',
    'Glib::Scalar',
);

### TREE STORE

use constant {
    TREECOL_NAME => 0,
    TREECOL_CHANGES => 1,
    TREECOL_KEYS => 2,
    TREECOL_VALUES => 3,
    TREECOL_ICON => 4,
};

my $tree_store = Gtk2::TreeStore->new(
    'Glib::String', 'Glib::Scalar', 'Glib::Scalar', 'Glib::Scalar',
    'Glib::String',
);

my $tree_view = Gtk2::TreeView->new($tree_store);

my $icon_cell = Gtk2::CellRendererPixbuf->new;
my $name_cell = Gtk2::CellRendererText->new;
my $tree_column0 = Gtk2::TreeViewColumn->new;
$tree_column0->set_title('Name');
$tree_column0->pack_start($icon_cell, FALSE);
$tree_column0->pack_start($name_cell, TRUE);
$tree_column0->set_attributes($icon_cell,
    'stock-id', TREECOL_ICON);
$tree_column0->set_attributes($name_cell,
    'text', TREECOL_NAME);
$tree_view->append_column($tree_column0);
$tree_column0->set_resizable(TRUE);

$tree_view->set_rules_hint(TRUE);

# row-expanded when row is expanded (e.g. after user clicks on arrow)
$tree_view->signal_connect('row-expanded' => \&expand_row);
$tree_view->signal_connect('row-collapsed' => \&collapse_row);
# row-activated when user double clicks on row
$tree_view->signal_connect('row-activated' => \&activate_row);

my $tree_selection = $tree_view->get_selection;
$tree_selection->set_mode('browse');
$tree_selection->signal_connect('changed' => \&tree_item_selected);

my $scrolled_tree_view = Gtk2::ScrolledWindow->new;
$scrolled_tree_view->set_policy('automatic', 'automatic');
$scrolled_tree_view->set_shadow_type('in');
$scrolled_tree_view->add($tree_view);

### LIST STORE

use constant {
    LISTCOL_FILENUM => 0,
    LISTCOL_CHANGE => 1,
    LISTCOL_ITEM_STRING => 2,
    LISTCOL_ITEM => 3,
    LISTCOL_ICON => 4,
};

my $list_store = Gtk2::ListStore->new(
    'Glib::String', 'Glib::String', 'Glib::String', 'Glib::Scalar',
    'Glib::String',
);

my $list_view = Gtk2::TreeView->new($list_store);

my $list_cell0 = Gtk2::CellRendererText->new;
my $list_column0 = Gtk2::TreeViewColumn->new_with_attributes(
    '', $list_cell0,
    'text', LISTCOL_FILENUM);
$list_view->append_column($list_column0);

my $list_cell2 = Gtk2::CellRendererText->new;
my $list_column2 = Gtk2::TreeViewColumn->new_with_attributes(
    'Change', $list_cell2,
    'text', LISTCOL_CHANGE);
$list_view->append_column($list_column2);
$list_column2->set_resizable(TRUE);

my $list_icon_cell = Gtk2::CellRendererPixbuf->new;
my $list_item_cell = Gtk2::CellRendererText->new;
my $list_column3 = Gtk2::TreeViewColumn->new;
$list_column3->pack_start($list_icon_cell, FALSE);
$list_column3->pack_start($list_item_cell, TRUE);
$list_column3->set_attributes($list_icon_cell,
    'stock-id', LISTCOL_ICON);
$list_column3->set_attributes($list_item_cell,
    'text', LISTCOL_ITEM_STRING);
$list_view->append_column($list_column3);
$list_column3->set_resizable(TRUE);
$list_item_cell->set('ellipsize', 'end');

$list_view->set_rules_hint(TRUE);
$list_view->set_headers_visible(FALSE);

my $list_selection = $list_view->get_selection;
$list_selection->set_mode('browse');
$list_selection->signal_connect('changed' => \&list_item_selected);

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

my $vpaned2 = Gtk2::VPaned->new;
$vpaned2->pack1($scrolled_list_view, FALSE, FALSE);
$vpaned2->pack2($scrolled_text_view, FALSE, FALSE);

### VPANED

my $vpaned1 = Gtk2::VPaned->new;
$vpaned1->pack1($scrolled_tree_view, FALSE, FALSE);
$vpaned1->pack2($vpaned2, FALSE, FALSE);

### UIMANAGER

my $uimanager = Gtk2::UIManager->new;

my @actions = (
    # name, stock id, label
    ['FileMenu', undef, '_File'],
    ['EditMenu', undef, '_Edit'],
    ['SearchMenu', undef, '_Search'],
    ['ViewMenu', undef, '_View'],
    ['HelpMenu', undef, '_Help'],
    # name, stock-id, label, accelerator, tooltip, callback
    ['Open', 'gtk-open', '_Select Files...', '<control>O', undef, \&open_files],
    ['Close', 'gtk-close', '_Close Files', '<control>W', undef, \&close_files],
    ['Quit', 'gtk-quit', '_Quit', '<control>Q', undef, \&quit],
    ['Copy', 'gtk-copy', '_Copy Path', '<control>C', undef, \&copy_path],
    ['Find', 'gtk-find', '_Find...', '<control>F', undef, \&find],
    ['FindNext', undef, 'Find _Next', '<control>G', undef, \&find_next],
    ['FindNext2', undef, 'Find Next', 'F3', undef, \&find_next],
    ['FindChange', 'gtk-find-and-replace', 'Find _Change...', '<control>N', undef, \&find_change],
    ['FindNextChange', undef, 'Find N_ext Change', '<control>M', undef, \&find_next_change],
    ['FindNextChange2', undef, 'Find Next Change', 'F4', undef, \&find_next_change],
    ['About', 'gtk-about', '_About...', undef, undef, \&about],
);

my $default_actions = Gtk2::ActionGroup->new('actions');
$default_actions->add_actions(\@actions, undef);

my @toggle_actions = (
    # name, stock id, label, accelerator, tooltip, callback, active
    ['ShowDetail', 'gtk-edit', 'Show _Detail', '<control>D', undef, \&toggle_item_detail, TRUE],
);
$default_actions->add_toggle_actions(\@toggle_actions, undef);

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
        <menu action='EditMenu'>
            <menuitem action='Copy'/>
        </menu>
        <menu action='SearchMenu'>
            <menuitem action='Find'/>
            <menuitem action='FindNext'/>
            <separator/>
            <menuitem action='FindChange'/>
            <menuitem action='FindNextChange'/>
        </menu>
        <menu action='ViewMenu'>
            <menuitem action='ShowDetail'/>
            <separator/>
        </menu>
        <menu action='HelpMenu'>
            <menuitem action='About'/>
        </menu>
    </menubar>
    <accelerator action='FindNext2'/>
    <accelerator action='FindNextChange2'/>
</ui>
END_OF_UI

$uimanager->add_ui_from_string($ui_info);

my $menubar = $uimanager->get_widget('/MenuBar');

### STATUSBAR

my $statusbar = Gtk2::Statusbar->new;

### VBOX

my $main_vbox = Gtk2::VBox->new(FALSE, 0);
$main_vbox->pack_start($menubar, FALSE, FALSE, 0);
$main_vbox->pack_start($vpaned1, TRUE, TRUE, 0);
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

###############################################################################

sub build_open_files_dialog {
    my $registry_view = Gtk2::TreeView->new($registry_store);
    $registry_view->set_reorderable(TRUE);

    my $registry_column0 = Gtk2::TreeViewColumn->new_with_attributes(
        'Filename', Gtk2::CellRendererText->new,
        'text', REGCOL_FILENAME);
    $registry_view->append_column($registry_column0);
    $registry_column0->set_resizable(TRUE);

    my $registry_column1 = Gtk2::TreeViewColumn->new_with_attributes(
        'Embedded Filename', Gtk2::CellRendererText->new,
        'text', REGCOL_EMBEDDED_FILENAME);
    $registry_view->append_column($registry_column1);
    $registry_column1->set_resizable(TRUE);

    my $registry_column2 = Gtk2::TreeViewColumn->new_with_attributes(
        'Embedded Timestamp', Gtk2::CellRendererText->new,
        'text', REGCOL_TIMESTAMP);
    $registry_view->append_column($registry_column2);
    $registry_column2->set_resizable(TRUE);

    my $registry_column3 = Gtk2::TreeViewColumn->new_with_attributes(
        'Directory', Gtk2::CellRendererText->new,
        'text', REGCOL_DIRECTORY);
    $registry_view->append_column($registry_column3);
    $registry_column3->set_resizable(TRUE);

    my $scrolled_registry_view = Gtk2::ScrolledWindow->new;
    $scrolled_registry_view->set_policy('automatic', 'automatic');
    $scrolled_registry_view->set_shadow_type('in');
    $scrolled_registry_view->add($registry_view);

    my $selection = $registry_view->get_selection;
    $selection->set_mode('multiple');

    my $label = Gtk2::Label->new;
    $label->set_markup('<i>Drag files to reorder them</i>');

    my $dialog = Gtk2::Dialog->new('Select Registry Files', $window, 'modal',
        'gtk-clear' => 70,
        'gtk-add' => 60,
        'gtk-remove' => 50,
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    $dialog->set_size_request($window_width * 1, $window_height * 0.8);
    $dialog->vbox->pack_start($scrolled_registry_view, TRUE, TRUE, 0);
    $dialog->vbox->pack_start($label, FALSE, FALSE, 5);
    $dialog->set_default_response('ok');

    $dialog->signal_connect(delete_event => sub {
        $dialog->hide;
        return TRUE;
    });
    $dialog->signal_connect(response => sub {
        my ($dialog, $response) = @_;
        if ($response eq '70') {
            $registry_store->clear;
        }
        elsif ($response eq '60') {
            my @filenames = choose_files();
            foreach my $filename (@filenames) {
                my ($name, $path) = fileparse($filename);
                if (my $registry = Parse::Win32Registry->new($filename)) {
                    if (my $root_key = $registry->get_root_key) {
                        add_registry($registry);
                    }
                }
                else {
                    show_message('error', "'$name' is not a registry file.");
                }
            }
        }
        elsif ($response eq '50') {
            my $selection = $registry_view->get_selection;
            my @paths = $selection->get_selected_rows;
            my @iters = map { $registry_store->get_iter($_) } @paths;
            foreach my $iter (@iters) {
                $registry_store->remove($iter);
            }
        }
        elsif ($response eq 'ok') {
            $dialog->hide;
            compare_files();
        }
        else {
            $dialog->hide;
        }
    });

    return $dialog;
}

my $open_files_dialog = build_open_files_dialog;

######################## GLOBAL SETUP

my @registries = ();
my @root_keys = ();

my $last_dir;

my $search_keys = TRUE;
my $search_values = TRUE;
my $search_selected = 0;
my $find_param = '';
my $find_iter;
my $change_iter;

if (@ARGV) {
    my @filenames = ();
    while (my $filename = shift) {
        push @filenames, $filename if -r $filename;
    }
    @filenames = map { File::Spec->rel2abs($_) } @filenames;
    foreach my $filename (@filenames) {
        if (my $registry = Parse::Win32Registry->new($filename)) {
            if (my $root_key = $registry->get_root_key) {
                add_registry($registry);
            }
        }
    }
}
compare_files();

Gtk2->main;

###############################################################################

sub expand_row {
    my ($view, $iter, $path) = @_;
    my $model = $view->get_model;

    # check that this is a key
    my $icon = $model->get($iter, TREECOL_ICON);
    if ($icon eq 'gtk-file') {
        return;
    }

    my $keys = $model->get($iter, TREECOL_KEYS);
    my $first_child_iter = $model->iter_nth_child($iter, 0);
    # add children if not already present
    if (!defined $model->get($first_child_iter, 0)) {
        add_children($keys, $model, $iter);
        $model->remove($first_child_iter);
    }
}

sub collapse_row {
    my ($view, $iter, $path) = @_;
}

sub activate_row {
    my ($view, $path, $column) = @_;
    if ($view->row_expanded($path)) {
        $view->collapse_row($path);
    }
    else {
        $view->expand_row($path, FALSE);
    }
}

sub toggle_item_detail {
    my ($toggle_action) = @_;
    if ($toggle_action->get_active) {
        $scrolled_text_view->show;
    }
    else {
        $scrolled_text_view->hide;
    }
}

sub tree_item_selected {
    my ($tree_selection) = @_;

    my ($model, $iter) = $tree_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $changes = $model->get($iter, TREECOL_CHANGES);
    my $keys = $model->get($iter, TREECOL_KEYS);
    my $values = $model->get($iter, TREECOL_VALUES);

    $list_store->clear;
    $text_buffer->set_text('');

    my $batch_size = @root_keys;

    if (defined $changes) {
        for (my $num = 0; $num < $batch_size; $num++) {
            my $item_as_string = '';
            my $item = '';
            my $icon = '';
            if (defined $values) { # values
                my $key = $keys->[$num];
                my $value = $values->[$num];
                if (defined $value) {
                    $item_as_string = $value->as_string;
                    $item = $value;
                    $icon = 'gtk-file';
                }
            }
            else { # keys
                my $key = $keys->[$num];
                if (defined $key) {
                    $item_as_string = $key->as_string;
                    $item = $key;
                    $icon = 'gtk-directory';
                }
            }
            $item_as_string = substr($item_as_string, 0, 500);
            $item_as_string =~ s/\0/[NUL]/g;
            my $iter = $list_store->append;
            $list_store->set($iter,
                LISTCOL_FILENUM, "[$num]",
                LISTCOL_CHANGE, $changes->[$num],
                LISTCOL_ITEM_STRING, $item_as_string,
                LISTCOL_ITEM, $item,
                LISTCOL_ICON, $icon);
        }
    }
    else {
        my $item_as_string = '';
        my $item = '';
        my $icon = '';
        if (defined $values) { # values
            my $any_value = (grep { defined } @$values)[0];
            $item_as_string = $any_value->as_string;
            $item = $any_value;
            $icon = 'gtk-file';
        }
        else { # keys
            my $any_key = (grep { defined } @$keys)[0];
            $item_as_string = $any_key->as_string;
            $item = $any_key;
            $icon = 'gtk-directory';
        }
        $item_as_string = substr($item_as_string, 0, 500);
        $item_as_string =~ s/\0/[NUL]/g;
        my $iter = $list_store->append;
        $list_store->set($iter,
            LISTCOL_FILENUM, "[*]",
            LISTCOL_CHANGE, "",
            LISTCOL_ITEM_STRING, $item_as_string,
            LISTCOL_ITEM, $item,
            LISTCOL_ICON, $icon);
    }


    my $status = '';
    my $any_key = (grep { defined } @$keys)[0];
    my $key_path = $any_key->get_path;
    if (defined $values) {
        my $any_value = (grep { defined } @$values)[0];
        my $name = $any_value->get_name;
        $name = "(Default)" if $name eq '';
        $status = "$key_path, $name";
    }
    else {
        $status = $key_path;
    }
    $status =~ s/\0/[NUL]/g;
    $statusbar->pop(0);
    $statusbar->push(0, $status);
}

sub list_item_selected {
    my ($list_selection) = @_;

    my ($model, $iter) = $list_selection->get_selected;
    if (!defined $model || !defined $iter) {
        return;
    }

    my $item = $model->get($iter, LISTCOL_ITEM);
    my $icon = $model->get($iter, LISTCOL_ICON);
    # there will be no item/icon for deleted items

    my $str = '';
    if (defined $item) {
        if ($icon eq 'gtk-file') { # item is a value
            $str .= hexdump($item->get_raw_data);
        }
        elsif ($icon eq 'gtk-directory') { # item is a key
            my $security = $item->get_security;
            if (defined $security) {
                my $sd = $security->get_security_descriptor;
                $str .= $sd->as_stanza;
            }
        }
    }
    $text_buffer->set_text($str);
}

sub compare_files {
    close_files(); # will clear @root_keys

    # Set up global variables: @registries, @root_keys
    @registries = ();
    my $iter = $registry_store->get_iter_first;
    while (defined $iter) {
        my $registry = $registry_store->get($iter, REGCOL_REGISTRY);
        push @registries, $registry;
        $iter = $registry_store->iter_next($iter);
    }
    @root_keys = map { $_->get_root_key } @registries;

    if (@registries > 0) {
        my $filename = $registries[0]->get_filename;
        my $basename = basename($filename);
        $basename .= ',...' if @registries > 1;
        $window->set_title("$basename - $script_name");
    }
    else {
        $window->set_title($script_name);
    }

    my $batch_size = @root_keys;

    # Create columns with a custom function to display changes
    for (my $num = 0; $num < $batch_size; $num++) {
        $tree_view->insert_column_with_data_func(
            $num + 1,
            "[$num]",
            Gtk2::CellRendererText->new,
            sub {
                my ($column, $cell, $model, $iter, $num) = @_;
                my $changes = $model->get($iter, TREECOL_CHANGES);
                if (defined $changes) {
                    my $diff = substr($changes->[$num], 0, 1);
                    $cell->set('text', $diff || "\x{00bb}");
                }
                else {
                    $cell->set('text', "\x{00b7}");
                }
            },
            $num, # additional data is passed to callback
        );
    }

    add_root(\@root_keys, $tree_store, undef);
}

sub add_root {
    my ($items, $model, $parent_iter) = @_;

    my @root_keys = @$items;

    return if @root_keys == 0;

    my $any_root_key = (grep { defined } @root_keys)[0];
    my $key_name = $any_root_key->get_name;
    $key_name =~ s/\0/[NUL]/g;

    my @changes = compare_multiple_keys(@root_keys);
    my $num_changes = grep { $_ } @changes;

    my $iter = $model->append($parent_iter);
    if ($num_changes > 0) {
        $model->set($iter,
            TREECOL_NAME, $key_name,
            TREECOL_CHANGES, \@changes,
            TREECOL_KEYS, \@root_keys,
            TREECOL_ICON, 'gtk-directory');
    }
    else {
        $model->set($iter,
            TREECOL_NAME, $key_name,
            #TREECOL_CHANGES, \@changes,
            TREECOL_KEYS, \@root_keys,
            TREECOL_ICON, 'gtk-directory');
    }
    my $dummy = $model->append($iter); # placeholder for children
}

sub add_children {
    my ($keys, $model, $parent_iter) = @_;

    my @keys = @$keys;

    my $subkeys_iter = make_multiple_subkey_iterator(@keys);

    while (defined(my $subkeys = $subkeys_iter->get_next)) {
        my @changes = compare_multiple_keys(@$subkeys);
        my $num_changes = grep { $_ } @changes;
        # insert a 'blank' change for missing subkeys
        for (my $i = 0; $i < @changes; $i++) {
            if ($changes[$i] eq '' && !defined $subkeys->[$i]) {
                $changes[$i] = ' ';
            }
        }

        my $any_subkey = (grep { defined } @$subkeys)[0];
        my $key_name = $any_subkey->get_name;
        $key_name =~ s/\0/[NUL]/g;

        my $iter = $model->append($parent_iter);

        if ($num_changes > 0) {
            $model->set($iter,
                TREECOL_NAME, $key_name,
                TREECOL_CHANGES, \@changes,
                TREECOL_KEYS, $subkeys,
                TREECOL_ICON, 'gtk-directory');
        }
        else {
            $model->set($iter,
                TREECOL_NAME, $key_name,
                #TREECOL_CHANGES, \@changes,
                TREECOL_KEYS, $subkeys,
                TREECOL_ICON, 'gtk-directory');
        }
        my $dummy = $model->append($iter); # placeholder for children
    }

    my $values_iter = make_multiple_value_iterator(@keys);

    while (defined(my $values = $values_iter->get_next)) {
        my @changes = compare_multiple_values(@$values);
        my $num_changes = grep { $_ } @changes;
        # insert a 'blank' change for missing values
        for (my $i = 0; $i < @changes; $i++) {
            if ($changes[$i] eq '' && !defined $values->[$i]) {
                $changes[$i] = ' ';
            }
        }

        my $any_value = (grep { defined } @$values)[0];
        my $value_name = $any_value->get_name;
        $value_name = "(Default)" if $value_name eq '';
        $value_name =~ s/\0/[NUL]/g;

        my $iter = $model->append($parent_iter);

        if ($num_changes > 0) {
            $model->set($iter,
                TREECOL_NAME, $value_name,
                TREECOL_CHANGES, \@changes,
                TREECOL_KEYS, $keys,
                TREECOL_VALUES, $values,
                TREECOL_ICON, 'gtk-file');
        }
        else {
            $model->set($iter,
                TREECOL_NAME, $value_name,
                #TREECOL_CHANGES, \@changes,
                TREECOL_KEYS, $keys,
                TREECOL_VALUES, $values,
                TREECOL_ICON, 'gtk-file');
        }
    }
}

sub add_registry {
    my $registry = shift;

    my $filename = $registry->get_filename;

    my $embedded_filename = $registry->get_embedded_filename;
    $embedded_filename = '' if !defined $embedded_filename;

    my $timestamp = $registry->get_timestamp;
    $timestamp = defined $timestamp ? $registry->get_timestamp_as_string : '';

    my $iter = $registry_store->append;
    $registry_store->set($iter,
        REGCOL_FILENAME, basename($filename),
        REGCOL_EMBEDDED_FILENAME, $embedded_filename,
        REGCOL_TIMESTAMP, $timestamp,
        REGCOL_DIRECTORY, dirname($filename),
        REGCOL_REGISTRY, $registry,
    );
}

sub choose_files {
    my $file_chooser = Gtk2::FileChooserDialog->new(
        'Select Registry File(s)',
        undef,
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    $file_chooser->set_select_multiple(TRUE);
    if (defined $last_dir) {
        $file_chooser->set_current_folder($last_dir);
    }
    my @filenames = ();
    my $response = $file_chooser->run;
    if ($response eq 'ok') {
        @filenames = $file_chooser->get_filenames;
    }
    $last_dir = $file_chooser->get_current_folder;
    $file_chooser->destroy;
    return @filenames;
}

sub open_files {
    # refresh $registry_store with contents of @registries...
    $registry_store->clear;
    foreach my $registry (@registries) {
        add_registry($registry);
    }

    $open_files_dialog->show_all;
}

sub close_files {
    @root_keys = ();
    # @registries is not cleared to retain currently selected files

    $find_param = '';
    $find_iter = undef;
    $change_iter = undef;

    $tree_store->clear;
    $list_store->clear;
    $text_buffer->set_text('');
    $statusbar->pop(0);

    my @columns = $tree_view->get_columns;
    shift @columns;
    foreach my $column (@columns) {
        $tree_view->remove_column($column);
    }
}

sub quit {
    $window->destroy;
}

sub about {
    Gtk2->show_about_dialog(undef,
        'program-name' => $script_name,
        'version' => $Parse::Win32Registry::VERSION,
        'copyright' => 'Copyright (c) 2008-2012 James Macfarlane',
        'comments' => 'GTK2 Registry Compare for the Parse::Win32Registry module',
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

sub get_location {
    my ($model, $iter) = $tree_selection->get_selected;
    if (defined $model && defined $iter) {
        my $keys = $model->get($iter, TREECOL_KEYS);
        my $values = $model->get($iter, TREECOL_VALUES);
        return ($keys, $values);
    }
    else {
        return ();
    }
}

sub copy_path {
    my ($keys, $values) = get_location;
    my $clip = '';
    if (defined $keys) {
        my $any_key = (grep { defined } @$keys)[0];

        if (defined $values) { # only values
            my $any_value = (grep { defined } @$values)[0];
            $clip = $any_key->get_path . ", " . $any_value->get_name;
        }
        else {
            $clip = $any_key->get_path;
        }
    }
    my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_CLIPBOARD);
    $clipboard->set_text($clip);
}

sub find_matching_child_iter {
    my ($iter, $name, $icon) = @_;

    return if !defined $iter;

    my $child_iter = $tree_store->iter_nth_child($iter, 0);
    if (!defined $child_iter) {
        return;
    }

    # Make sure children are real
    if (!defined $tree_store->get($child_iter, 0)) {
        my $keys = $tree_store->get($iter, TREECOL_KEYS);
        add_children($keys, $tree_store, $iter);
        $tree_store->remove($child_iter); # remove dummy items
        $child_iter = $tree_store->iter_nth_child($iter, 0); # refetch items
    }

    while (defined $child_iter) {
        my $child_icon = $tree_store->get($child_iter, TREECOL_ICON);

        if ($icon eq 'gtk-directory') {
            my $child_keys = $tree_store->get($child_iter, TREECOL_KEYS);
            my $any_child_key = (grep { defined } @$child_keys)[0];
            if ($any_child_key->get_name eq $name) {
                return $child_iter; # match found
            }
        }
        else {
            my $child_values = $tree_store->get($child_iter, TREECOL_VALUES);
            if (defined $child_values) {
                my $any_child_value = (grep { defined } @$child_values)[0];
                if ($any_child_value->get_name eq $name) {
                    return $child_iter; # match found
                }
            }
        }

        $child_iter = $tree_store->iter_next($child_iter);
    }
    return; # no match found
}

sub go_to_subkey_and_value {
    my $subkey_path = shift;
    my $value_name = shift;

    my @path_components = index($subkey_path, "\\") == -1
                        ? ($subkey_path)
                        : split(/\\/, $subkey_path, -1);

    my $iter = $tree_store->get_iter_first;
    return if !defined $iter; # no registry loaded

    while (defined(my $subkey_name = shift @path_components)) {
        my $keys = $tree_store->get($iter, TREECOL_KEYS);
        if (@$keys == 0) {
            return;
        }

        $iter = find_matching_child_iter($iter, $subkey_name, 'gtk-directory');
        if (!defined $iter) {
            return; # no matching child iter
        }

        if (@path_components == 0) {
            # Look for a value if a value name has been supplied
            if (defined $value_name) {
                $iter = find_matching_child_iter($iter, $value_name, 'gtk-file');
                if (!defined $iter) {
                    return; # no matching child iter
                }
            }
            my $parent_iter = $tree_store->iter_parent($iter);
            my $parent_path = $tree_store->get_path($parent_iter);
            $tree_view->expand_to_path($parent_path);
            my $tree_path = $tree_store->get_path($iter);
            $tree_view->scroll_to_cell($tree_path);
            $tree_view->set_cursor($tree_path);
            $window->set_focus($tree_view);
            return; # match found
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
        my ($keys, $values) = $find_iter->get_next;

        if (!defined $keys) {
            $dialog->response('ok');
            return FALSE; # stop searching
        }

        # Obtain the name and path from the first defined key
        my $any_key = (grep { defined } @$keys)[0];
        my $subkey_path = (split(/\\/, $any_key->get_path, 2))[1];
        if (!defined $subkey_path) {
            return TRUE;
        }

        # Check values (if defined) for a match
        if (defined $values) {
            if ($search_values) {
                my $any_value = (grep { defined } @$values)[0];
                my $value_name = $any_value->get_name;
                if (index(lc $value_name, lc $find_param) >= 0) {
                    go_to_subkey_and_value($subkey_path, $value_name);
                    $dialog->response(50);
                    return FALSE; # stop searching
                }
            }
            return TRUE; # continue searching
        }

        # Check keys for a match
        if ($search_keys) {
            my $key_name = $any_key->get_name;
            if (index(lc $key_name, lc $find_param) >= 0) {
                go_to_subkey_and_value($subkey_path);
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
    return if @root_keys == 0;

    my ($selected_keys, $selected_values) = get_location;

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
    if (!defined $selected_keys) {
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
    if ($response eq 'ok' && @root_keys > 0) {
        $search_keys = $check1->get_active;
        $search_values = $check2->get_active;
        $search_selected = $radio2->get_active;
        $find_param = $entry->get_text;
        $dialog->destroy;
        $find_iter = undef;
        if ($find_param ne '') {
            $find_iter = $search_selected
                       ? make_multiple_subtree_iterator(@$selected_keys)
                       : make_multiple_subtree_iterator(@root_keys);
            find_next;
        }
    }
    else {
        $dialog->destroy;
    }
}

sub find_next_change {
    if (!defined $change_iter) {
        return;
    }

    my $label = Gtk2::Label->new;
    $label->set_text(get_search_message);
    my $dialog = Gtk2::Dialog->new('Find Change',
        $window,
        'modal',
        'gtk-cancel' => 'cancel',
    );
    $dialog->vbox->pack_start($label, TRUE, TRUE, 5);
    $dialog->set_default_response('cancel');
    $dialog->show_all;

    my $id = Glib::Idle->add(sub {
        my ($keys, $values) = $change_iter->get_next;

        if (!defined $keys) {
            $dialog->response('ok');
            return FALSE; # stop searching
        }

        # Obtain the name and path from the first defined key
        my $any_key = (grep { defined } @$keys)[0];
        my $subkey_path = (split(/\\/, $any_key->get_path, 2))[1];
        if (!defined $subkey_path) {
            return TRUE;
        }

        # Check values (if defined) for changes
        if (defined $values) {
            if ($search_values) {
                my $any_value = (grep { defined } @$values)[0];
                my $value_name = $any_value->get_name;
                my @changes = compare_multiple_values(@$values);
                my $num_changes = grep { $_ } @changes;
                if ($num_changes > 0) {
                    go_to_subkey_and_value($subkey_path, $value_name);
                    $dialog->response(50);
                    return FALSE; # stop searching
                }
            }
            return TRUE; # continue searching
        }

        if ($search_keys) {
            my $key_name = $any_key->get_name;
            my @changes = compare_multiple_keys(@$keys);
            my $num_changes = grep { $_ } @changes;
            if ($num_changes > 0) {
                go_to_subkey_and_value($subkey_path);
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

sub find_change {
    return if @root_keys == 0;

    my ($selected_keys, $selected_values) = get_location;

    my $label = Gtk2::Label->new('Search for a change:');
    $label->set_alignment(0, 0);
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
    if (!defined $selected_keys) {
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
        $dialog->destroy;
        $change_iter = $search_selected
                     ? make_multiple_subtree_iterator(@$selected_keys)
                     : make_multiple_subtree_iterator(@root_keys);
        $change_iter->get_next; # skip the starting key
        find_next_change;
    }
    else {
        $dialog->destroy;
    }
}
