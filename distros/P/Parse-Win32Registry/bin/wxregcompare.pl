#!/usr/bin/perl
use strict;
use warnings;

binmode STDOUT, ':utf8';

use Parse::Win32Registry 0.51;


package EntryTreeCtrl;

use Parse::Win32Registry qw(make_multiple_subkey_iterator
                            make_multiple_value_iterator
                            compare_multiple_keys
                            compare_multiple_values);
use Wx qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);
use Wx::Event qw(:everything);

use base qw(Wx::TreeCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxTR_DEFAULT_STYLE|wxBORDER_SUNKEN);
    bless $self, $class;

    EVT_TREE_ITEM_EXPANDING($self, $self, \&OnTreeItemExpanding);

    my $imagelist = Wx::ImageList->new(16, 16, 1);
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_FOLDER, wxART_MENU, [16, 16]));
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_NORMAL_FILE, wxART_MENU, [16, 16]));
    $self->AssignImageList($imagelist);

    return $self;
}

sub Clear {
    my ($self) = @_;

    $self->DeleteAllItems;
}

sub SetRootKeys {
    my ($self, $root_keys) = @_;

    return if !defined $root_keys || @$root_keys == 0;

    my $any_root_key = (grep { defined } @$root_keys)[0];

    my $name = $any_root_key->get_name;
    $name =~ s/\0/[NUL]/g;
    $name =~ s/\n/[LF]/g;
    $name =~ s/\r/[CR]/g;

    my @changes = compare_multiple_keys(@$root_keys);
    my $num_changes = grep { $_ } @changes;
    $name .= " ($num_changes)" if $num_changes > 0;

    my $root_item = $self->AddRoot($name, 0, -1);
    $self->SetItemBold($root_item, $num_changes); # bold if $num_changes > 0
    $self->SetPlData($root_item, [\@changes, $root_keys]);

    $self->AddChildren($root_item, $root_keys);
}

sub AddChildren {
    my ($self, $item, $keys) = @_;

    my $any_key = (grep { defined } @$keys)[0];

    my $subkey_count = 0;
    my $subkeys_iter = make_multiple_subkey_iterator(@$keys);
    while (defined(my $subkeys = $subkeys_iter->get_next)) {
        my $any_subkey = (grep { defined } @$subkeys)[0];

        my $name = $any_subkey->get_name;
        $name =~ s/\0/[NUL]/g;
        $name =~ s/\n/[LF]/g;
        $name =~ s/\r/[CR]/g;

        my @changes = compare_multiple_keys(@$subkeys);
        my $num_changes = grep { $_ } @changes;
        $name .= " ($num_changes)" if $num_changes > 0;

        my $child_item = $self->AppendItem($item, $name, 0, -1);
        $self->SetPlData($child_item, [\@changes, $subkeys]);
        $self->SetItemBold($child_item, $num_changes);
        $self->SetItemHasChildren($child_item, 1);

        $subkey_count++;
    }

    my $value_count = 0;
    my $values_iter = make_multiple_value_iterator(@$keys);
    while (defined(my $values = $values_iter->get_next)) {
        my $any_value = (grep { defined } @$values)[0];

        my $name = $any_value->get_name;
        $name = "(Default)" if $name eq '';
        $name =~ s/\0/[NUL]/g;
        $name =~ s/\n/[LF]/g;
        $name =~ s/\r/[CR]/g;

        my @changes = compare_multiple_values(@$values);
        my $num_changes = grep { $_ } @changes;
        $name .= " ($num_changes)" if $num_changes > 0;

        my $child_item = $self->AppendItem($item, $name, 1, -1);
        $self->SetPlData($child_item, [\@changes, $keys, $values]);
        $self->SetItemBold($child_item, $num_changes);

        $value_count++;
    }
    return $subkey_count + $value_count;
}

sub OnTreeItemExpanding {
    my ($self, $event) = @_;

    my $item = $event->GetItem;

    my ($child_item, $cookie) = $self->GetFirstChild($item);
    if ($child_item->IsOk) {
        return;
    }

    my ($changes, $keys) = @{$self->GetPlData($item)};
    if (!$self->AddChildren($item, $keys)) {
        $self->SetItemHasChildren($item, 0);
    }
}

sub FindMatchingKey {
    my ($self, $item, $key_name) = @_;

    return if !$self->ItemHasChildren($item);

    # Make any virtual children real before proceeding
    my ($child_item, $cookie) = $self->GetFirstChild($item);
    if (!$child_item->IsOk) { # children still virtual
        my $data = $self->GetPlData($item);
        my ($changes, $keys, $values) = @$data;
        if (!$self->AddChildren($item, $keys)) {
            $self->SetItemHasChildren($item, 0);
        }
    }

    # Look through the children for a match
    ($child_item, $cookie) = $self->GetFirstChild($item);
    while ($child_item->IsOk) {
        my $data = $self->GetPlData($child_item);
        my ($changes, $keys, $values) = @$data;

        if (!defined $values) { # only keys
            my $any_key = (grep { defined } @$keys)[0];
            if ($key_name eq $any_key->get_name) {
                return $child_item; # found a match
            }
        }

        ($child_item, $cookie) = $self->GetNextChild($item, $cookie);
    }

    return; # no match
}

sub FindMatchingValue {
    my ($self, $item, $value_name) = @_;

    return if !$self->ItemHasChildren($item);

    # Make any virtual children real before proceeding
    my ($child_item, $cookie) = $self->GetFirstChild($item);
    if (!$child_item->IsOk) { # children still virtual
        my $data = $self->GetPlData($item);
        my ($changes, $keys, $values) = @$data;
        if (!$self->AddChildren($item, $keys)) {
            $self->SetItemHasChildren($item, 0);
        }
    }

    # Look through the children for a match
    ($child_item, $cookie) = $self->GetFirstChild($item);
    while ($child_item->IsOk) {
        my $data = $self->GetPlData($child_item);
        my ($changes, $keys, $values) = @$data;

        if (defined $values) { # only values
            my $any_value = (grep { defined } @$values)[0];
            if ($value_name eq $any_value->get_name) {
                return $child_item; # found a match
            }
        }
        ($child_item, $cookie) = $self->GetNextChild($item, $cookie);
    }

    return; # no match
}

sub GoToEntry {
    my ($self, $subkey_path, $value_name) = @_;

    my $item = $self->GetRootItem;

    if (defined $subkey_path) {
        my @key_names = split(/\\/, $subkey_path);

        while (@key_names) {
            my $key_name = shift @key_names;

            $item = $self->FindMatchingKey($item, $key_name);

            if (!defined $item) {
                return; # no match found
            }
        }
    }

    if (defined $value_name) {
        $item = $self->FindMatchingValue($item, $value_name);
        if (!defined $item) {
            return; # no match found
        }
    }

    $self->EnsureVisible($item);
    $self->SelectItem($item);
}

sub GetSelectedEntry {
    my ($self) = @_;

    my $item = $self->GetSelection;
    if ($item->IsOk) {
        my $data = $self->GetPlData($item);
        my ($changes, $keys, $values) = @$data;
        return ($changes, $keys, $values);
    }
    return;
}


package EntryListCtrl;

use Wx qw(:everything);

use base qw(Wx::ListCtrl);

# Colors used for highlighting changes:
use constant COLOR_ADDED   => Wx::Colour->new('#b0ffb0'); # green
use constant COLOR_CHANGED => Wx::Colour->new('#ffffb0'); # yellow
use constant COLOR_DELETED => Wx::Colour->new('#ffb0b0'); # red

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_SINGLE_SEL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, '', wxLIST_FORMAT_LEFT);
    $self->InsertColumn(1, 'Change', wxLIST_FORMAT_LEFT);
    $self->InsertColumn(2, 'Timestamp/Type', wxLIST_FORMAT_LEFT);
    $self->InsertColumn(3, 'Class/Data', wxLIST_FORMAT_LEFT);

    $self->SetColumnWidth(0, 40);
    $self->SetColumnWidth(1, 100);
    $self->SetColumnWidth(2, 200);
    $self->SetColumnWidth(3, 200);

    return $self;
}

sub SetEntries {
    my ($self, $changes, $keys, $values) = @_;

    if (defined $values) {
        # change first column title
        my $column = $self->GetColumn(2);
        $column->SetText('Type');
        $column->SetWidth($column->GetWidth);
        $column->SetImage(-1);
        $self->SetColumn(2, $column);
        # change second column title
        $column = $self->GetColumn(3);
        $column->SetText('Data');
        $column->SetWidth($self->GetColumnWidth(3));
        $column->SetImage(-1);
        $self->SetColumn(3, $column);
    }
    else {
        # change first column title
        my $column = $self->GetColumn(2);
        $column->SetText('Timestamp');
        $column->SetWidth($column->GetWidth);
        $column->SetImage(-1);
        $self->SetColumn(2, $column);
        # change second column title
        $column = $self->GetColumn(3);
        $column->SetText('Class Name');
        $column->SetWidth($self->GetColumnWidth(3));
        $column->SetImage(-1);
        $self->SetColumn(3, $column);
    }

    $self->DeleteAllItems;
    my $index = 0;
    for (my $i = 0; $i < @$changes; $i++) {
        my $change = $changes->[$i];

        my $key = $keys->[$i];

        my $column1 = '';
        my $column2 = '';

        if (defined $values) {
            my $value = $values->[$i];

            if (defined $value) {
                $column1 = $value->get_type_as_string;
                $column2 = substr($value->get_data_as_string, 0, 200);
            }
        }
        else {
            if (defined $key) {
                if (defined $key->get_timestamp) {
                    $column1 = $key->get_timestamp_as_string;
                }
                if (defined $key->get_class_name) {
                    $column2 = $key->get_class_name;
                }
            }
        }

        # Only the data or the class name needs checking
        $column2 =~ s/\0/[NUL]/g;
        $column2 =~ s/\n/[LF]/g;
        $column2 =~ s/\r/[CR]/g;

        $index = $self->InsertStringItem($index+1, "[$i]");
        $self->SetItem($index, 1, $change);
        $self->SetItem($index, 2, $column1);
        $self->SetItem($index, 3, $column2);

        # Color item
        if ($change eq 'NEWER' || $change eq 'ADDED') {
            $self->SetItemBackgroundColour($index, COLOR_ADDED);
        }
        elsif ($change eq 'CHANGED') {
            $self->SetItemBackgroundColour($index, COLOR_CHANGED);
        }
        elsif ($change eq 'OLDER' || $change eq 'DELETED') {
            $self->SetItemBackgroundColour($index, COLOR_DELETED);
        }
    }

    $self->{_changes} = $changes;
    $self->{_keys} = $keys;
    $self->{_values} = $values;
}

sub GetEntry {
    my ($self, $index) = @_;

    my $change = $self->{_changes}[$index];
    my $key = $self->{_keys}[$index];

    if (defined $self->{_values}) {
        my $value = $self->{_values}[$index];
        if (defined $value) {
            return ($change, $key, $value);
        }
        else {
            # No $key is returned when there is no $value to make 
            # the recipient realise that this is a list of $value changes.
            # This does require that the recipient anticipates receiving
            # neither a $key nor a $value.
            return ($change);
        }
    }
    else {
        return ($change, $key);
    }
}


package CompareFrame;

use File::Basename;
use FindBin;
use Parse::Win32Registry qw(make_multiple_subtree_iterator
                            compare_multiple_keys 
                            compare_multiple_values
                            hexdump);
use Wx qw(:everything);
use Wx::DND; # required for copying to clipboard
use Wx::Event qw(:everything);

use base qw(Wx::Frame);

use constant ID_DUMP_ENTRIES => Wx::NewId;
use constant ID_FIND_NEXT => Wx::NewId;
use constant ID_FIND_CHANGE => Wx::NewId;
use constant ID_FIND_NEXT_CHANGE => Wx::NewId;
use constant ID_SELECT_FONT => Wx::NewId;

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Registry Compare", wxDefaultPosition, [600, 400]);
    bless $self, $class;

    $self->SetMinSize([600, 400]);

    my $menu1 = Wx::Menu->new;
    $menu1->Append(wxID_OPEN, "&Select Files...\tCtrl+O");
    $menu1->Append(wxID_CLOSE, "&Close Files\tCtrl+W");
    $menu1->AppendSeparator;
    $menu1->Append(wxID_EXIT, "E&xit\tAlt+F4");

    my $menu2 = Wx::Menu->new;
    $menu2->Append(wxID_COPY, "&Copy Path\tCtrl+C");

    my $menu3 = Wx::Menu->new;
    $menu3->Append(wxID_FIND, "&Find...\tCtrl+F");
    $menu3->Append(ID_FIND_NEXT, "Find &Next...\tF3");
    $menu3->AppendSeparator;
    $menu3->Append(wxID_REPLACE, "Find &Change...\tCtrl+N");
    $menu3->Append(ID_FIND_NEXT_CHANGE, "Find N&ext Change...\tF4");

    my $menu4 = Wx::Menu->new;
    $menu4->Append(ID_SELECT_FONT, "Select &Font...");

    my $menu5 = Wx::Menu->new;
    $menu5->Append(wxID_ABOUT, "&About...");

    my $menubar = Wx::MenuBar->new;
    $menubar->Append($menu1, "&File");
    $menubar->Append($menu2, "&Edit");
    $menubar->Append($menu3, "&Search");
    $menubar->Append($menu4, "&View");
    $menubar->Append($menu5, "&Help");

    $self->SetMenuBar($menubar);

    my $statusbar = Wx::StatusBar->new($self, -1);
    $self->SetStatusBar($statusbar);

    EVT_MENU($self, wxID_OPEN, \&OnOpenFiles);
    EVT_MENU($self, wxID_CLOSE, \&OnCloseFiles);
    EVT_MENU($self, wxID_EXIT, \&OnQuit);
    EVT_MENU($self, wxID_COPY, \&OnCopy);
    EVT_MENU($self, wxID_FIND, \&OnFind);
    EVT_MENU($self, ID_FIND_NEXT, \&FindNext);
    EVT_MENU($self, wxID_REPLACE, \&OnFindChange);
    EVT_MENU($self, ID_FIND_NEXT_CHANGE, \&FindNextChange);
    EVT_MENU($self, ID_SELECT_FONT, \&OnSelectFont);
    EVT_MENU($self, wxID_ABOUT, \&OnAbout);

    my $hsplitter = Wx::SplitterWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    my $tree = EntryTreeCtrl->new($hsplitter);

    my $vsplitter = Wx::SplitterWindow->new($hsplitter, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    $hsplitter->SplitVertically($tree, $vsplitter);
    $hsplitter->SetMinimumPaneSize(10);

    my $list = EntryListCtrl->new($vsplitter);

    my $text = Wx::TextCtrl->new($vsplitter, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_DONTWRAP|wxTE_READONLY);
    $text->SetFont(Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL));

    $vsplitter->SplitHorizontally($list, $text);
    $vsplitter->SetMinimumPaneSize(10);

    $self->{_tree} = $tree;
    $self->{_list} = $list;
    $self->{_text} = $text;
    $self->{_statusbar} = $statusbar;

    EVT_SPLITTER_DCLICK($self, $hsplitter, \&OnSplitterDClick);
    EVT_SPLITTER_DCLICK($self, $vsplitter, \&OnSplitterDClick);

    EVT_TREE_SEL_CHANGED($self, $tree, \&OnEntryTreeSelChanged);
    EVT_LIST_ITEM_SELECTED($self, $list, \&OnEntryListItemSelected);

    $self->SetIcon(Wx::GetWxPerlIcon());

    my $accelerators = Wx::AcceleratorTable->new(
        [wxACCEL_CTRL, ord('Q'), wxID_EXIT],
    );
    $self->SetAcceleratorTable($accelerators);

    if (@ARGV) {
        $self->LoadFiles(@ARGV);
    }
    else {
        $self->{_registries} = [];
    }

    return $self;
}

sub OnSelectFont {
    my ($self, $event) = @_;

    my $text = $self->{_text};
    my $font = $text->GetFont;
    $font = Wx::GetFontFromUser($self, $font);
    if ($font->IsOk) {
        $text->SetFont($font);
    }
}

sub OnCopy {
    my ($self, $event) = @_;

    my ($changes, $keys, $values) = $self->{_tree}->GetSelectedEntry;
    my $clip = '';
    if (defined $keys) {
        my $any_key = (grep { defined } @$keys)[0];

        if (defined $values) {
            my $any_value = (grep { defined } @$values)[0];
            $clip = $any_key->get_path . ", " . $any_value->get_name;
        }
        else {
            $clip = $any_key->get_path;
        }
    }
    wxTheClipboard->Open;
    wxTheClipboard->SetData(Wx::TextDataObject->new($clip));
    wxTheClipboard->Close;
}

sub OnSplitterDClick {
    my ($self, $event) = @_;

    $event->Veto;
}

sub OnEntryTreeSelChanged {
    my ($self, $event) = @_;

    my $item = $event->GetItem;
    my ($changes, $keys, $values) = @{$self->{_tree}->GetPlData($item)};

    my $any_key = (grep { defined } @$keys)[0];

    my $key_path = $any_key->get_path;
    $key_path =~ s/\0/[NUL]/g;
    $key_path =~ s/\n/[LF]/g;
    $key_path =~ s/\r/[CR]/g;

    # find currently selected item in entry list
    $item = $self->{_list}->GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
    $item = 0 if $item == -1;

    if (defined $values) {
        my $any_value = (grep { defined } @$values)[0];
        my $name = $any_value->get_name;
        $name = "(Default)" if $name eq '';
        $name =~ s/\0/[NUL]/g;
        $name =~ s/\n/[LF]/g;
        $name =~ s/\r/[CR]/g;

        $self->{_list}->SetEntries($changes, $keys, $values);
        $self->{_statusbar}->SetStatusText("$key_path, $name");
    }
    else {
        $self->{_list}->SetEntries($changes, $keys);
        $self->{_statusbar}->SetStatusText($key_path);
    }

    $self->{_text}->ChangeValue('');

    $self->{_list}->SetItemState($item, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
}

sub OnEntryListItemSelected {
    my ($self, $event) = @_;

    my ($change, $key, $value) = $self->{_list}->GetEntry($event->GetIndex);

    my $details = '';
    if (defined $value) {
        $details = hexdump($value->get_raw_data);
    }
    elsif (defined $key) {
        if (defined $key->get_timestamp) {
            $details .= "Timestamp: " . $key->get_timestamp_as_string . "\n";
        }

        my $class_name = $key->get_class_name;
        if (defined $class_name) {
            $class_name =~ s/\0/[NUL]/g;
            $class_name =~ s/\n/[NL]/g;
            $class_name =~ s/\r/[CR]/g;
            $details .= "Class Name: $class_name\n";
        }

        my $security = $key->get_security;
        if (defined $security) {
            my $sd = $security->get_security_descriptor;
            $details .= $sd->as_stanza;
        }
    }

    $self->{_text}->ChangeValue($details);
}

sub OnAbout {
    my ($self, $event) = @_;

    my $info = Wx::AboutDialogInfo->new;
    $info->SetName($FindBin::Script);
    $info->SetVersion($Parse::Win32Registry::VERSION);
    $info->SetCopyright("Copyright (c) 2010-2012 James Macfarlane");
    $info->SetDescription("wxWidgets Registry Compare for the Parse::Win32Registry module");
    Wx::AboutBox($info);
}

sub FindNext {
    my ($self) = @_;

    my $find_param = $self->{_find_param};
    my $find_iter = $self->{_find_iter};
    my $search_keys = $self->{_search_keys};
    my $search_values = $self->{_search_values};

    return if !defined $find_param || $find_param eq '';
    return if !defined $find_iter;

    my $start = time;

    my $max = 0;
    my $progress_dialog;

    my $iter_finished = 1;

    while (my ($keys, $values) = $find_iter->get_next) {

        my $any_key = (grep { defined } @$keys)[0];
        my $key_name = $any_key->get_name;
        my $key_path = $any_key->get_path;

        # strip root key name from path to get subkey path
        my $subkey_path = (split(/\\/, $key_path, 2))[1];

        if (defined $values) {
            if ($search_values) { # check value for match
                my $any_value = (grep { defined } @$values)[0];
                my $value_name = $any_value->get_name;
                if (index(lc $value_name, lc $find_param) >= 0) {
                    $self->{_tree}->GoToEntry($subkey_path, $value_name);
                    $iter_finished = 0;
                    last;
                }
            }
        }
        elsif ($search_keys) { # check key for match
            if (index(lc $key_name, lc $find_param) >= 0) {
                $self->{_tree}->GoToEntry($subkey_path);
                $iter_finished = 0;
                last;
            }
        }

        if (defined $progress_dialog) {
            if (!$progress_dialog->Update) {
                # Cancelled!
                $iter_finished = 0;
                last;
            }
        }
        else {
            # display progress dialog if search is slow
            if (time - $start >= 1) {
                $progress_dialog = Wx::ProgressDialog->new('Find',
                    'Searching registry...', $max, $self,
                    wxPD_CAN_ABORT|wxPD_AUTO_HIDE);
            }
        }
    }

    if (defined $progress_dialog) {
        $progress_dialog->Destroy;
    }

    if ($iter_finished) {
        my $dialog = Wx::MessageDialog->new($self,
            'Finished searching', 'Find', wxICON_EXCLAMATION|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
    }
    $self->{_tree}->SetFocus;
    $self->SetFocus;
}

sub OnFind {
    my ($self, $event) = @_;

    my $root_keys = $self->{_root_keys};

    return if !defined $root_keys || @$root_keys == 0;

    my $dialog = FindDialog->new($self);
    $dialog->SetText($self->{_find_param});
    $dialog->SetSearchKeys($self->{_search_keys});
    $dialog->SetSearchValues($self->{_search_values});
    $dialog->SetSearchSelected($self->{_search_selected});

    if ($dialog->ShowModal == wxID_OK) {
        $self->{_find_param} = $dialog->GetText;

        $self->{_search_keys} = $dialog->GetSearchKeys;
        $self->{_search_values} = $dialog->GetSearchValues;
        if (!$self->{_search_keys} && !$self->{_search_values}) {
            $self->{_search_keys} = $self->{_search_values} = 1;
        }

        my ($changes, $keys, $values) = $self->{_tree}->GetSelectedEntry;

        my $search_selected = $self->{_search_selected}
                            = $dialog->GetSearchSelected;

        $self->{_find_iter} = $search_selected
                            ? make_multiple_subtree_iterator(@$keys)
                            : make_multiple_subtree_iterator(@$root_keys);

        $self->FindNext;
    }
    $dialog->Destroy;
}

sub FindNextChange {
    my ($self) = @_;

    my $change_iter = $self->{_change_iter};
    my $search_keys = $self->{_search_keys};
    my $search_values = $self->{_search_values};

    return if !defined $change_iter;

    my $start = time;

    my $max = 0;
    my $progress_dialog;

    my $iter_finished = 1;

    while (my ($keys, $values) = $change_iter->get_next) {

        my $any_key = (grep { defined } @$keys)[0];
        my $key_name = $any_key->get_name;
        my $key_path = $any_key->get_path;

        # strip root key name from path to get subkey path
        my $subkey_path = (split(/\\/, $key_path, 2))[1];

        if (defined $values) {
            if ($search_values) { # check value for match
                my $any_value = (grep { defined } @$values)[0];
                my $value_name = $any_value->get_name;
                my @changes = compare_multiple_values(@$values);
                my $num_changes = grep { $_ } @changes;
                if ($num_changes > 0) {
                    $self->{_tree}->GoToEntry($subkey_path, $value_name);
                    $iter_finished = 0;
                    last;
                }
            }
        }
        elsif ($search_keys) { # check key for match
            my @changes = compare_multiple_keys(@$keys);
            my $num_changes = grep { $_ } @changes;
            if ($num_changes > 0) {
                $self->{_tree}->GoToEntry($subkey_path);
                $iter_finished = 0;
                last;
            }
        }

        if (defined $progress_dialog) {
            if (!$progress_dialog->Update) {
                # Cancelled!
                $iter_finished = 0;
                last;
            }
        }
        else {
            # display progress dialog if search is slow
            if (time - $start >= 1) {
                $progress_dialog = Wx::ProgressDialog->new('Find',
                    'Searching registry...', $max, $self,
                    wxPD_CAN_ABORT|wxPD_AUTO_HIDE);
            }
        }
    }

    if (defined $progress_dialog) {
        $progress_dialog->Destroy;
    }

    if ($iter_finished) {
        my $dialog = Wx::MessageDialog->new($self,
            'Finished searching', 'Find', wxICON_EXCLAMATION|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
    }
    $self->{_tree}->SetFocus;
    $self->SetFocus;
}

sub OnFindChange {
    my ($self, $event) = @_;

    my $root_keys = $self->{_root_keys};

    return if !defined $root_keys || @$root_keys == 0;

    my $dialog = FindChangeDialog->new($self);
    $dialog->SetSearchKeys($self->{_search_keys});
    $dialog->SetSearchValues($self->{_search_values});
    $dialog->SetSearchSelected($self->{_search_selected});

    if ($dialog->ShowModal == wxID_OK) {
        $self->{_search_keys} = $dialog->GetSearchKeys;
        $self->{_search_values} = $dialog->GetSearchValues;
        if (!$self->{_search_keys} && !$self->{_search_values}) {
            $self->{_search_keys} = $self->{_search_values} = 1;
        }

        my ($changes, $keys, $values) = $self->{_tree}->GetSelectedEntry;

        my $search_selected = $self->{_search_selected}
                            = $dialog->GetSearchSelected;

        $self->{_change_iter} = $search_selected
                              ? make_multiple_subtree_iterator(@$keys)
                              : make_multiple_subtree_iterator(@$root_keys);
        $self->{_change_iter}->get_next; # skip the starting key
        $self->FindNextChange;
    }
    $dialog->Destroy;
}

sub LoadFiles {
    my ($self, @filenames) = @_;

    my @registries;
    my @root_keys;

    foreach my $filename (@filenames) {
        if (!-r $filename) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$filename' cannot be read",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        my $basename = basename($filename);

        my $registry = Parse::Win32Registry->new($filename);
        if (!defined $registry) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$basename' is not a registry file",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        my $root_key = $registry->get_root_key;
        if (!defined $registry) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$basename' has no root key",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        push @registries, $registry;
        push @root_keys, $root_key;
    }

    $self->LoadRegistries(\@registries);
}

sub LoadRegistries {
    my ($self, $registries) = @_;

    my @root_keys = map { $_->get_root_key } @$registries;

    $self->{_registries} = $registries;
    $self->{_tree}->SetRootKeys(\@root_keys);
    $self->{_tree}->SetFocus;
    $self->{_root_keys} = \@root_keys;
    if (@$registries) {
        my $filename = $registries->[0]->get_filename;
        $filename = basename($filename);
        if (@$registries > 1) {
            $filename .= " (+" . (@$registries - 1) . ")";
        }
        $self->SetTitle("$filename - Registry Compare");
    }
    else {
        $self->SetTitle("Registry Compare");
    }
}

sub OnOpenFiles {
    my ($self, $event) = @_;

    my $dialog = $self->{_files_dialog};
    if (!defined $dialog) {
        $dialog = $self->{_files_dialog} = FilesDialog->new($self);
    }

    # The original list of registries is not passed by reference
    # (as any changes would immediately affect the original).
    my @registries = @{$self->{_registries}};
    $dialog->SetRegistries(\@registries);

    my $result = $dialog->ShowModal;
    $dialog->Hide;

    return if $result != wxID_OK;

    my $registries = $dialog->GetRegistries;

    # clear
    $self->OnCloseFiles;

    # set up
    $self->LoadRegistries($registries);
}

sub OnCloseFiles {
    my ($self, $event) = @_;

    $self->{_tree}->Clear;
    $self->{_list}->SetEntries([]);
    $self->{_text}->Clear;
    $self->{_statusbar}->SetStatusText('');
    # $self->{_registries} is not cleared to retain currently selected files
    $self->{_root_keys} = undef;
    $self->{_find_iter} = undef;
    $self->{_changed_entries} = undef;
    $self->SetTitle("Registry Compare");
    if (defined $self->{_change_list_dialog}) {
        $self->{_change_list_dialog}->SetChangedEntries([]);
        $self->{_change_list_dialog}->Hide;
    }
}

sub OnQuit {
    my ($self) = @_;

    $self->Close;
}


package FindDialog;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(Wx::Dialog);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Find", wxDefaultPosition, wxDefaultSize, wxDEFAULT_DIALOG_STYLE);
    bless $self, $class;

    my $static = Wx::StaticText->new($self, -1, 'Enter text to &search for:');
    my $text = Wx::TextCtrl->new($self, -1, '');
    my $check1 = Wx::CheckBox->new($self, -1, 'Search &keys');
    my $check2 = Wx::CheckBox->new($self, -1, 'Search &values');
    my $radio = Wx::RadioBox->new($self, -1, 'Start searching', wxDefaultPosition, wxDefaultSize, ['from root key', 'from current key'], 1);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($static, 0, wxEXPAND|wxALL, 5);
    $sizer->Add($text, 0, wxEXPAND|wxALL, 5);
    $sizer->Add($check1, 0, wxALL, 5);
    $sizer->Add($check2, 0, wxALL, 5);
    $sizer->Add($radio, 0, wxALL, 5);

    my $hsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    my $button_sizer = $self->CreateSeparatedButtonSizer(wxOK|wxCANCEL);

    $sizer->Add($button_sizer, 0, wxEXPAND|wxALL, 5);

    $self->SetSizer($sizer);

    $self->{_text} = $text;
    $self->{_check1} = $check1;
    $self->{_check2} = $check2;
    $self->{_radio} = $radio;

    $self->Fit; # resize dialog to best fit child windows

    $self->{_text}->SetFocus;
    $self->SetFocus;

    EVT_CHECKBOX($self, $check1, sub {
        if (!$check1->GetValue && !$check2->GetValue) {
            $check2->SetValue(1);
        }
    });
    EVT_CHECKBOX($self, $check2, sub {
        if (!$check1->GetValue && !$check2->GetValue) {
            $check1->SetValue(1);
        }
    });

    return $self;
}

sub GetSearchKeys {
    my ($self) = @_;
    return $self->{_check1}->GetValue;
}

sub GetSearchValues {
    my ($self) = @_;
    return $self->{_check2}->GetValue;
}

sub GetText {
    my ($self) = @_;
    return $self->{_text}->GetValue;
}

sub GetSearchSelected {
    my ($self) = @_;
    return $self->{_radio}->GetSelection;
}

sub SetSearchKeys {
    my ($self, $state) = @_;
    $state = 1 if !defined $state;
    $self->{_check1}->SetValue($state);
}

sub SetSearchValues {
    my ($self, $state) = @_;
    $state = 1 if !defined $state;
    $self->{_check2}->SetValue($state);
}

sub SetText {
    my ($self, $value) = @_;
    $value = '' if !defined $value;
    $self->{_text}->ChangeValue($value);
    $self->{_text}->SetSelection(-1, -1);
}

sub SetSearchSelected {
    my ($self, $n) = @_;
    $n = 0 if !defined $n;
    $self->{_radio}->SetSelection($n);
}


package FindChangeDialog;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(Wx::Dialog);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Find", wxDefaultPosition, wxDefaultSize, wxDEFAULT_DIALOG_STYLE);
    bless $self, $class;

    my $static = Wx::StaticText->new($self, -1, 'Search for a change:');
    my $check1 = Wx::CheckBox->new($self, -1, 'Search &keys');
    my $check2 = Wx::CheckBox->new($self, -1, 'Search &values');
    my $radio = Wx::RadioBox->new($self, -1, 'Start searching', wxDefaultPosition, wxDefaultSize, ['from root key', 'from current key'], 1);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($static, 0, wxEXPAND|wxALL, 5);
    $sizer->Add($check1, 0, wxALL, 5);
    $sizer->Add($check2, 0, wxALL, 5);
    $sizer->Add($radio, 0, wxALL, 5);

    my $hsizer = Wx::BoxSizer->new(wxHORIZONTAL);

    my $button_sizer = $self->CreateSeparatedButtonSizer(wxOK|wxCANCEL);

    $sizer->Add($button_sizer, 0, wxEXPAND|wxALL, 5);

    $self->SetSizer($sizer);

    $self->{_check1} = $check1;
    $self->{_check2} = $check2;
    $self->{_radio} = $radio;

    $self->Fit; # resize dialog to best fit child windows

    $self->{_radio}->SetFocus;
    $self->SetFocus;

    EVT_CHECKBOX($self, $check1, sub {
        if (!$check1->GetValue && !$check2->GetValue) {
            $check2->SetValue(1);
        }
    });
    EVT_CHECKBOX($self, $check2, sub {
        if (!$check1->GetValue && !$check2->GetValue) {
            $check1->SetValue(1);
        }
    });

    return $self;
}

sub GetSearchKeys {
    my ($self) = @_;
    return $self->{_check1}->GetValue;
}

sub GetSearchValues {
    my ($self) = @_;
    return $self->{_check2}->GetValue;
}

sub GetSearchSelected {
    my ($self) = @_;
    return $self->{_radio}->GetSelection;
}

sub SetSearchKeys {
    my ($self, $state) = @_;
    $state = 1 if !defined $state;
    $self->{_check1}->SetValue($state);
}

sub SetSearchValues {
    my ($self, $state) = @_;
    $state = 1 if !defined $state;
    $self->{_check2}->SetValue($state);
}

sub SetSearchSelected {
    my ($self, $n) = @_;
    $n = 0 if !defined $n;
    $self->{_radio}->SetSelection($n);
}


package FileListCtrl;

use File::Basename;
use Parse::Win32Registry qw(iso8601);
use Wx qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);
use Wx::Event qw(:everything);

use base qw(Wx::ListCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_VIRTUAL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, "Filename", wxLIST_FORMAT_LEFT);
    $self->InsertColumn(1, "Embedded Filename", wxLIST_FORMAT_LEFT);
    $self->InsertColumn(2, "Embedded Timestamp", wxLIST_FORMAT_LEFT);
    $self->InsertColumn(3, "Directory", wxLIST_FORMAT_LEFT);

    $self->SetColumnWidth(0, 200);
    $self->SetColumnWidth(1, 200);
    $self->SetColumnWidth(2, 200);
    $self->SetColumnWidth(3, 200);

    my $imagelist = Wx::ImageList->new(16, 16, 1);
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_NORMAL_FILE, wxART_MENU, [16, 16]));
    $self->AssignImageList($imagelist, wxIMAGE_LIST_SMALL);

    $self->{_registries} = [];

    return $self;
}

sub MoveItems {
    my ($self, $source_items, $target_item) = @_;

    # build list of items to move
    my @items;
    foreach my $source_item (@$source_items) {
        push @items, @{$self->{_registries}}[$source_item];
    }

    # delete originals
    foreach my $source_item (reverse @$source_items) {
        if ($source_item < $target_item) {
            $target_item--;
        }
        splice @{$self->{_registries}}, $source_item, 1;
    }

    # insert moved items
    if ($target_item == -1 || $target_item > @{$self->{_registries}}) {
        push @{$self->{_registries}}, @items;
    }
    else {
        splice @{$self->{_registries}}, $target_item, 0, @items;
    }
    $self->Refresh;

    # deselect
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        $self->SetItemState($item, 0, wxLIST_STATE_SELECTED);
    }

    # reselect
    if ($target_item == -1 || $target_item > (@{$self->{_registries}} - @items)) {
        $target_item = @{$self->{_registries}} - @items;
    }

    for (my $item = 0; $item < @items; $item++) {
        $self->SetItemState($target_item + $item, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
    }
}

sub MoveSelectedItemsToTop {
    my ($self) = @_;

    # iterate selected items in list:
    my @items;
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        push @items, $item;
    }

    return if @items == 0;

    $self->MoveItems(\@items, 0);

    $self->EnsureVisible(0);
}

sub MoveSelectedItemsToBottom {
    my ($self) = @_;

    # iterate selected items in list:
    my @items;
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        push @items, $item;
    }

    return if @items == 0;

    $self->MoveItems(\@items, -1);

    $self->EnsureVisible(scalar @{$self->{_registries}} - 1);
}

sub MoveSelectedItemsUp {
    my ($self) = @_;

    # iterate selected items in list:
    my @items;
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        push @items, $item;
    }

    return if @items == 0;

    my $target_item = $items[0] - 1;
    $target_item = 0 if $target_item < 0;

    $self->MoveItems(\@items, $target_item);

    $self->EnsureVisible($target_item);
}

sub MoveSelectedItemsDown {
    my ($self) = @_;

    # iterate selected items in list:
    my @items;
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        push @items, $item;
    }

    return if @items == 0;

    my $target_item = $items[-1] + 2;

    $self->MoveItems(\@items, $target_item);

    $self->EnsureVisible($target_item - 1);
}

sub GetRegistries {
    my ($self) = @_;

    return $self->{_registries};
}

sub SetRegistries {
    my ($self, $registries) = @_;

    $self->{_registries} = $registries;
    $self->SetItemCount(scalar @$registries);
    $self->Refresh;
}

sub AddRegistries {
    my ($self, $registries) = @_;

    push @{$self->{_registries}}, @$registries;
    $self->SetItemCount(scalar @{$self->{_registries}});
    $self->Refresh;
}

sub RemoveSelectedRegistries {
    my ($self) = @_;

    # iterate items in list:
    my @items;
    my $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        push @items, $item;
    }

    # delete items
    foreach my $item (reverse @items) {
        splice @{$self->{_registries}}, $item, 1;
    }
    $self->SetItemCount(scalar @{$self->{_registries}});
    $self->Refresh;

    # deselect
    $item = -1;
    while (1) {
        $item = $self->GetNextItem($item, wxLIST_NEXT_ALL, wxLIST_STATE_SELECTED);
        last if $item == -1;
        $self->SetItemState($item, 0, wxLIST_STATE_SELECTED);
    }
}

sub OnGetItemText {
    my ($self, $index, $column) = @_;

    my $registry = $self->{_registries}[$index];
    if ($column == 0) {
        return basename $registry->get_filename;
    }
    elsif ($column == 1) {
        my $embedded_filename = $registry->get_embedded_filename;
        return defined $embedded_filename ? $embedded_filename : '';
    }
    elsif ($column == 2) {
        my $embedded_timestamp = $registry->get_timestamp;
        return defined $embedded_timestamp ? iso8601($embedded_timestamp) : '';
    }
    elsif ($column == 3) {
        return dirname $registry->get_filename;
    }
    else {
        return '?';
    }
}

sub OnGetItemImage {
    return 0;
}


package FilesDialog;

use File::Basename;
use Wx qw(:everything);
use Wx::Event qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);

use base qw(Wx::Dialog);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Select Registry Files", wxDefaultPosition, [600, 400], wxDEFAULT_FRAME_STYLE);
    bless $self, $class;

    $self->SetMinSize([600, 400]);

    my $static1 = Wx::StaticText->new($self, -1, 'Select files to compare:');

    my $button1 = Wx::Button->new($self, wxID_CLEAR, 'Clear');
    my $button2 = Wx::Button->new($self, wxID_ADD, 'Add');
    my $button3 = Wx::Button->new($self, wxID_REMOVE, 'Remove');
    my $button4 = Wx::Button->new($self, -1, 'Move &Up');
    my $button5 = Wx::Button->new($self, -1, 'Move &Down');
    my $button6 = Wx::Button->new($self, -1, 'Move To &Top');
    my $button7 = Wx::Button->new($self, -1, 'Move To &Bottom');

    my $list = FileListCtrl->new($self);

    my $hsizer1 = Wx::BoxSizer->new(wxHORIZONTAL);
    $hsizer1->Add($button1, 0, wxEXPAND|wxALL, 5);
    $hsizer1->Add($button2, 0, wxEXPAND|wxALL, 5);
    $hsizer1->Add($button3, 0, wxEXPAND|wxALL, 5);

    my $hsizer2 = Wx::BoxSizer->new(wxHORIZONTAL);
    $hsizer2->Add($button4, 0, wxEXPAND|wxALL, 5);
    $hsizer2->Add($button5, 0, wxEXPAND|wxALL, 5);
    $hsizer2->Add($button6, 0, wxEXPAND|wxALL, 5);
    $hsizer2->Add($button7, 0, wxEXPAND|wxALL, 5);

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($static1, 0, wxEXPAND|wxALL, 5);
    $sizer->Add($hsizer1, 0, wxEXPAND);
    $sizer->Add($list, 1, wxEXPAND);
    $sizer->Add($hsizer2, 0, wxEXPAND);

    my $button_sizer = $self->CreateButtonSizer(wxOK|wxCANCEL);

    $sizer->Add($button_sizer, 0, wxEXPAND|wxALL, 5);

    EVT_CLOSE($self, \&OnClose);

    $self->SetSizer($sizer);

    $self->{_list} = $list;

    EVT_BUTTON($self, $button1, \&OnClear);
    EVT_BUTTON($self, $button2, \&OnAdd);
    EVT_BUTTON($self, $button3, \&OnRemove);
    EVT_BUTTON($self, $button4, sub {
        $list->MoveSelectedItemsUp;
    });
    EVT_BUTTON($self, $button5, sub {
        $list->MoveSelectedItemsDown;
    });
    EVT_BUTTON($self, $button6, sub {
        $list->MoveSelectedItemsToTop;
    });
    EVT_BUTTON($self, $button7, sub {
        $list->MoveSelectedItemsToBottom;
    });

    $self->SetFocus;

    return $self;
}

sub OnAdd {
    my ($self, $event) = @_;

    my $dialog = Wx::FileDialog->new($self, "Select Registry File(s)", $self->{_directory} || '', '', '*', wxFD_OPEN|wxFD_MULTIPLE);

    if ($dialog->ShowModal != wxID_OK) {
        return;
    }

    $self->{_directory} = $dialog->GetDirectory;

    my @registries = ();
    foreach my $filename ($dialog->GetPaths) {
        if (!-r $filename) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$filename' cannot be read",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        my $basename = basename($filename);

        my $registry = Parse::Win32Registry->new($filename);
        if (!defined $registry) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$basename' is not a registry file",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        my $root_key = $registry->get_root_key;
        if (!defined $registry) {
            my $dialog = Wx::MessageDialog->new($self,
                "'$basename' has no root key",
                'Error', wxICON_ERROR|wxOK);
            $dialog->ShowModal;
            $dialog->Destroy;
            next;
        }

        push @registries, $registry;
    }

    $self->{_list}->AddRegistries(\@registries);
}

sub OnRemove {
    my ($self, $event) = @_;

    $self->{_list}->RemoveSelectedRegistries;
}

sub OnClear {
    my ($self) = @_;

    $self->{_list}->SetRegistries([]);
}

sub SetRegistries {
    my ($self, $registries) = @_;

    $registries = [] if !defined $registries;
    $self->{_list}->SetRegistries($registries);
}

sub OnClose {
    my ($self, $event) = @_;

    $self->EndModal(wxID_CANCEL);
}

sub GetRegistries {
    my ($self) = @_;

    return $self->{_list}->GetRegistries;
}


package CompareApp;

use Wx qw(:everything);

use base qw(Wx::App);

sub OnInit {
    my $self = shift;

    my $frame = CompareFrame->new(undef);
    $frame->Show;

    return 1;
}


package main;

my $app = CompareApp->new;
$app->MainLoop;
