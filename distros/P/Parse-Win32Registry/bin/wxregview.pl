#!/usr/bin/perl
use strict;
use warnings;

binmode STDOUT, ':utf8';

use Parse::Win32Registry 0.51;


package KeyTreeCtrl;

use Wx qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);
use Wx::Event qw(:everything);

use base qw(Wx::TreeCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxTR_DEFAULT_STYLE|wxBORDER_SUNKEN);
    bless $self, $class;

    my $imagelist = Wx::ImageList->new(16, 16, 1);
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_FOLDER, wxART_MENU, [16, 16]));
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_NORMAL_FILE, wxART_MENU, [16, 16]));
    $self->AssignImageList($imagelist);

    EVT_TREE_ITEM_EXPANDING($self, $self, \&OnTreeItemExpanding);

    return $self;
}

sub Clear {
    my ($self) = @_;

    $self->DeleteAllItems;
}

sub SetRootKey {
    my ($self, $root_key) = @_;

    my $name = $root_key->get_name;
    $name =~ s/\0/[NUL]/g;
    $name =~ s/\n/[LF]/g;
    $name =~ s/\r/[CR]/g;

    my $root_item = $self->AddRoot($name, 0, -1);
    $self->SetPlData($root_item, $root_key);

    $self->AddChildren($root_item, $root_key);
}

sub AddChildren {
    my ($self, $item, $key) = @_;

    my @subkeys = $key->get_list_of_subkeys;
    foreach my $subkey (@subkeys) {
        my $name = $subkey->get_name;
        $name =~ s/\0/[NUL]/g;
        $name =~ s/\n/[LF]/g;
        $name =~ s/\r/[CR]/g;

        my $child_item = $self->AppendItem($item, $name, 0, -1);
        $self->SetPlData($child_item, $subkey);
        $self->SetItemHasChildren($child_item, 1);
    }
    return scalar @subkeys;
}

sub OnTreeItemExpanding {
    my ($self, $event) = @_;

    my $item = $event->GetItem;

    my ($child_item, $cookie) = $self->GetFirstChild($item);
    if ($child_item->IsOk) {
        return; # already populated
    }

    my $key = $self->GetPlData($item);
    if (!$self->AddChildren($item, $key)) {
        $self->SetItemHasChildren($item, 0);
    }
}

sub FindMatchingItem {
    my ($self, $key_name, $item) = @_;

    return if !$self->ItemHasChildren($item);

    # Make any virtual children real before proceeding
    my ($child_item, $cookie) = $self->GetFirstChild($item);
    if (!$child_item->IsOk) { # children still virtual
        my $key = $self->GetPlData($item);
        if (!$self->AddChildren($item, $key)) {
            $self->SetItemHasChildren($item, 0);
        }
    }

    # Look through the children for a match
    ($child_item, $cookie) = $self->GetFirstChild($item);
    while ($child_item->IsOk) {
        my $key = $self->GetPlData($child_item);

        if ($key_name eq $key->get_name) {
            return $child_item; # found a match
        }
        ($child_item, $cookie) = $self->GetNextChild($item, $cookie);
    }

    return; # no match
}

sub GoToSubkey {
    my ($self, $subkey_path) = @_;

    my $item = $self->GetRootItem;

    my @key_names = split(/\\/, $subkey_path, -1);

#    my @key_names = index($subkey_path, "\\") == -1
#                        ? ($subkey_path)
#                        : split(/\\/, $subkey_path, -1);

    # If the first method is chosen, it is possible to go to the root key,
    # but a first-level subkey with no name will be inaccessible.
    # This is because an empty string will produce an empty array,
    # causing the following while loop to be skipped,
    # leaving $item set to the root.

    # If the second method is chosen, it is possible to go to a first-level
    # subkey with no name, but the root key will be inaccessible.
    # This is because an array with at least one string in it is produced,
    # causing the following while loop to be entered, and either
    # the first-level subkey will be found and $item will be set to it,
    # or it will not be found, and the subroutine will return
    # without going to any item.

    while (@key_names) {
        my $key_name = shift @key_names;

        $item = $self->FindMatchingItem($key_name, $item);

        if (!defined $item) {
            return; # no match found
        }
    }

    # match found, in $item
    $self->EnsureVisible($item);
    $self->SelectItem($item);
}

sub GetSelectedKey {
    my ($self) = @_;

    my $item = $self->GetSelection;
    if ($item->IsOk) {
        my $key = $self->GetPlData($item);
        return $key;
    }
    return;
}


package ValueListCtrl;

use Wx qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);

use base qw(Wx::ListCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_SINGLE_SEL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, "Name", wxLIST_FORMAT_LEFT);
    $self->InsertColumn(1, "Type", wxLIST_FORMAT_LEFT);
    $self->InsertColumn(2, "Data", wxLIST_FORMAT_LEFT);

    $self->SetColumnWidth(0, 150);
    $self->SetColumnWidth(1, 100);
    $self->SetColumnWidth(2, 150);

    my $imagelist = Wx::ImageList->new(16, 16, 1);
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_NORMAL_FILE, wxART_MENU, [16, 16]));
    $self->AssignImageList($imagelist, wxIMAGE_LIST_SMALL);

    return $self;
}

sub SetKey {
    my ($self, $key) = @_;

    return unless $key->can('get_list_of_values');

    my @values = $key->get_list_of_values;
    $self->DeleteAllItems;
    my $index = 0;
    foreach my $value (@values) {
        my $name = $value->get_name;
        $name = "(Default)" if $name eq '';
        $name =~ s/\0/[NUL]/g;
        $name =~ s/\n/[LF]/g;
        $name =~ s/\r/[CR]/g;

        my $type = $value->get_type_as_string;

        my $data = substr($value->get_data_as_string, 0, 200);
        $data =~ s/\0/[NUL]/g;
        $data =~ s/\n/[LF]/g;
        $data =~ s/\r/[CR]/g;

        $index = $self->InsertImageStringItem($index+1, $name, 0);
        $self->SetItem($index, 1, $type);
        $self->SetItem($index, 2, $data);
    }

    $self->{_key} = $key;
    $self->{_values} = \@values;
}

sub GetValue {
    my ($self, $index) = @_;

    return $self->{_values}[$index];
}

sub Clear {
    my ($self) = @_;

    $self->DeleteAllItems;
    $self->{_key} = undef;
    $self->{_values} = undef;
}

sub GoToValue {
    my ($self, $value_name) = @_;

    for (my $index = 0; $index < @{$self->{_values}}; $index++) {
        if ($value_name eq $self->{_values}[$index]->get_name) {
            $self->EnsureVisible($index);
            $self->SetItemState($index, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
        }
    }
}


package ViewFrame;

use File::Basename;
use FindBin;
use Parse::Win32Registry qw(hexdump);
use Wx qw(:everything);
use Wx::DND; # required for copying to clipboard
use Wx::Event qw(:everything);

use base qw(Wx::Frame);

use constant ID_DUMP_KEYS => Wx::NewId;
use constant ID_FIND_NEXT => Wx::NewId;
use constant ID_TIMELINE => Wx::NewId;
use constant ID_SELECT_FONT => Wx::NewId;

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Registry Viewer", wxDefaultPosition, [600, 400]);
    bless $self, $class;

    $self->SetMinSize([600, 400]);

    my $menu1 = Wx::Menu->new;
    $menu1->Append(wxID_OPEN, "&Open...\tCtrl+O");
    $menu1->Append(wxID_CLOSE, "&Close\tCtrl+W");
    $menu1->AppendSeparator;
    $menu1->Append(wxID_EXIT, "E&xit\tAlt+F4");

    my $menu2 = Wx::Menu->new;
    $menu2->Append(wxID_COPY, "&Copy Key Path\tCtrl+C");

    my $menu3 = Wx::Menu->new;
    $menu3->Append(wxID_FIND, "&Find...\tCtrl+F");
    $menu3->Append(ID_FIND_NEXT, "Find &Next\tF3");
    $menu3->AppendSeparator;
    $menu3->Append(ID_TIMELINE, "Show &Timeline...");

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

    EVT_MENU($self, wxID_OPEN, \&OnOpenFile);
    EVT_MENU($self, wxID_CLOSE, \&OnCloseFile);
    EVT_MENU($self, wxID_EXIT, \&OnQuit);
    EVT_MENU($self, wxID_COPY, \&OnCopy);
    EVT_MENU($self, wxID_FIND, \&OnFind);
    EVT_MENU($self, ID_FIND_NEXT, \&FindNext);
    EVT_MENU($self, ID_TIMELINE, \&ShowTimeline);
    EVT_MENU($self, wxID_ABOUT, \&OnAbout);
    EVT_MENU($self, ID_SELECT_FONT, \&OnSelectFont);

    my $hsplitter = Wx::SplitterWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    my $tree = KeyTreeCtrl->new($hsplitter);

    my $vsplitter = Wx::SplitterWindow->new($hsplitter, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    $hsplitter->SplitVertically($tree, $vsplitter);
    $hsplitter->SetMinimumPaneSize(10);

    my $list = ValueListCtrl->new($vsplitter);

    my $text = Wx::TextCtrl->new($vsplitter, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_DONTWRAP|wxTE_READONLY);
    # Set a monospaced font
    $text->SetFont(Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL));

    $vsplitter->SplitHorizontally($list, $text);
    $vsplitter->SetMinimumPaneSize(10);

    $self->{_tree} = $tree;
    $self->{_list} = $list;
    $self->{_text} = $text;
    $self->{_statusbar} = $statusbar;

    EVT_SPLITTER_DCLICK($self, $hsplitter, \&OnSplitterDClick);
    EVT_SPLITTER_DCLICK($self, $vsplitter, \&OnSplitterDClick);

    EVT_TREE_SEL_CHANGED($self, $tree, \&OnKeyTreeSelChanged);
    EVT_LIST_ITEM_SELECTED($self, $list, \&OnValueListItemSelected);

    $self->SetIcon(Wx::GetWxPerlIcon());

    my $accelerators = Wx::AcceleratorTable->new(
        [wxACCEL_CTRL, ord('Q'), wxID_EXIT],
    );
    $self->SetAcceleratorTable($accelerators);

    my $filename = shift @ARGV;
    if (defined $filename) {
        $self->LoadFile($filename);
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

sub OnSplitterDClick {
    my ($self, $event) = @_;

    $event->Veto;
}

sub ShowTimeline {
    my ($self, $event) = @_;

    return if !defined $self->{_root_key};

    my $dialog = $self->{_timeline_dialog};
    if (!defined $dialog) {
        $dialog = $self->{_timeline_dialog} = TimelineDialog->new($self);
        # OnKeyListItemSelected
        EVT_LIST_ITEM_SELECTED($self, $dialog->{_list2}, sub {
            my ($self, $event) = @_;
            my $index = $event->GetIndex;
            my $key = $dialog->{_list2}->GetKey($index);
            if (defined $key) {
                my $subkey_path = (split(/\\/, $key->get_path, 2))[1];
                $self->{_tree}->GoToSubkey($subkey_path);
            }
        });
        # OnKeyListItemActivated
        EVT_LIST_ITEM_ACTIVATED($self, $dialog->{_list2}, sub {
            my ($self, $event) = @_;
            $self->Raise;
        });
        my $font = $self->{_tree}->GetFont;
        $dialog->{_list1}->SetFont($font);
        $dialog->{_list2}->SetFont($font);
    }

    if (!defined $self->{_keys_by_time}) {
        $self->BuildTimeline;
        return if !defined $self->{_keys_by_time}; # build was cancelled
        $dialog->SetTimeline($self->{_keys_by_time});
    }

    if (scalar keys %{$self->{_keys_by_time}} == 0) {
        my $dialog = Wx::MessageDialog->new($self,
            'No keys have timestamps!', 'Timeline', wxICON_ERROR|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
        return;
    }

    $dialog->Show;
    $dialog->Raise;
    $dialog->{_list1}->SetFocus;
}

sub BuildTimeline {
    my ($self) = @_;

    return if defined $self->{_keys_by_time};

    my $root_key = $self->{_root_key};

    return if !defined $root_key;

    my $subtree_iter = $root_key->get_subtree_iterator;

    my %keys_by_time = ();

    my $max = 0;
    my $progress_dialog = Wx::ProgressDialog->new('Building Timeline',
        'Ordering registry keys...', $max, $self, 
        wxPD_CAN_ABORT|wxPD_AUTO_HIDE);
    $progress_dialog->Update;

    while (my $key = $subtree_iter->get_next) {
        my $time = $key->get_timestamp;
        push @{$keys_by_time{$time}}, $key if defined $time;

        if (!$progress_dialog->Update) {
            # Cancelled!
            $progress_dialog->Destroy;
            return;
        }
    }

    $self->{_keys_by_time} = \%keys_by_time;

    $progress_dialog->Destroy;
}

sub OnCopy {
    my ($self, $event) = @_;

    my $key = $self->{_tree}->GetSelectedKey;
    my $clip = '';
    if (defined $key) {
        $clip = $key->get_path;
    }
    wxTheClipboard->Open;
    wxTheClipboard->SetData(Wx::TextDataObject->new($clip));
    wxTheClipboard->Close;
}

sub OnKeyTreeSelChanged {
    my ($self, $event) = @_;

    my $item = $event->GetItem;
    my $key = $self->{_tree}->GetPlData($item);

    $self->{_list}->SetKey($key);

    return if !$key->can('get_list_of_values');

    my $details = '';
    if (defined $key->get_timestamp) {
        $details .= "Timestamp: " . $key->get_timestamp_as_string . "\n";
    }
    my $class_name = $key->get_class_name;
    if (defined $class_name) {
        $class_name =~ s/\0/[NUL]/g;
        $class_name =~ s/\n/[LF]/g;
        $class_name =~ s/\r/[CR]/g;
        $details .= "Class Name: $class_name\n";
    }

    my $security = $key->get_security;
    if (defined $security) {
        my $sd = $security->get_security_descriptor;
        $details .= $sd->as_stanza;
    }

    $self->{_text}->ChangeValue($details);

    my $key_str = $key->as_string;
    $key_str =~ s/\0/[NUL]/g;
    $key_str =~ s/\n/[LF]/g;
    $key_str =~ s/\r/[CR]/g;
    $self->{_statusbar}->SetStatusText($key_str);
}

sub OnValueListItemSelected {
    my ($self, $event) = @_;

    my $value = $self->{_list}->GetValue($event->GetIndex);

    my $details = hexdump($value->get_raw_data);

    $self->{_text}->ChangeValue($details);
}

sub OnAbout {
    my ($self, $event) = @_;

    my $info = Wx::AboutDialogInfo->new;
    $info->SetName($FindBin::Script);
    $info->SetVersion($Parse::Win32Registry::VERSION);
    $info->SetCopyright('Copyright (c) 2010-2012 James Macfarlane');
    $info->SetDescription('wxWidgets Registry Viewer for the Parse::Win32Registry module');
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

    while (my ($key, $value) = $find_iter->get_next) {

        my $key_name = $key->get_name;
        my $key_path = $key->get_path;

        # strip root key name from path to get subkey path
        my $subkey_path = (split(/\\/, $key_path, 2))[1];

        if (defined $value) { # check value for match
            if ($search_values) {
                my $value_name = $value->get_name;
                if (index(lc $value_name, lc $find_param) >= 0) {
                    $self->{_tree}->GoToSubkey($subkey_path);
                    $self->{_list}->GoToValue($value_name);
                    $self->{_list}->SetFocus;
                    $self->SetFocus;
                    $iter_finished = 0;
                    last;
                }
            }
        }
        elsif ($search_keys) { # check key for match
            if (index(lc $key_name, lc $find_param) >= 0) {
                $self->{_tree}->GoToSubkey($subkey_path);
                $self->{_tree}->SetFocus;
                $self->SetFocus;
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
}

sub OnFind {
    my ($self, $event) = @_;

    my $root_key = $self->{_root_key};
    return if !defined $root_key;

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

        my $selected_key = $self->{_tree}->GetSelectedKey;
        my $search_selected = $self->{_search_selected}
                            = $dialog->GetSearchSelected;

        $self->{_find_iter} = $search_selected
                            ? $selected_key->get_subtree_iterator
                            : $root_key->get_subtree_iterator;
        $self->FindNext;
    }
    $dialog->Destroy;
}

sub LoadFile {
    my ($self, $filename) = @_;

    if (!-r $filename) {
        my $dialog = Wx::MessageDialog->new($self,
            "'$filename' cannot be read", 'Error', wxICON_ERROR|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
        return
    }

    my $basename = basename($filename);

    my $registry = Parse::Win32Registry->new($filename);
    if (!defined $registry) {
        my $dialog = Wx::MessageDialog->new($self,
            "'$basename' is not a registry file", 'Error', wxICON_ERROR|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
        return
    }

    my $root_key = $registry->get_root_key;
    if (!defined $registry) {
        my $dialog = Wx::MessageDialog->new($self,
            "'$basename' has no root key", 'Error', wxICON_ERROR|wxOK);
        $dialog->ShowModal;
        $dialog->Destroy;
        return;
    }

    # clear
    $self->OnCloseFile;

    # set up
    $self->{_root_key} = $root_key;
    $self->{_tree}->SetRootKey($root_key);
    $self->{_tree}->SetFocus;
    $self->SetTitle("$basename - Registry Viewer");
}

sub OnOpenFile {
    my ($self, $event) = @_;

    my $dialog = Wx::FileDialog->new($self, 'Select Registry File', $self->{_directory} || '');

    if ($dialog->ShowModal != wxID_OK) {
        return;
    }

    my $filename = $dialog->GetPath;
    $self->{_directory} = $dialog->GetDirectory;

    $self->LoadFile($filename);
}

sub OnCloseFile {
    my ($self, $event) = @_;
    $self->{_tree}->Clear;
    $self->{_list}->Clear;
    $self->{_text}->Clear;
    $self->{_statusbar}->SetStatusText('');
    $self->{_root_key} = undef;
    $self->{_find_iter} = undef;
    $self->{_keys_by_time} = undef;
    $self->SetTitle("Registry Viewer");
    if (defined $self->{_timeline_dialog}) {
        $self->{_timeline_dialog}->SetTimeline({});
        $self->{_timeline_dialog}->Hide;
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


package TimeListCtrl;

use Parse::Win32Registry qw(iso8601);
use Wx qw(:everything);

use base qw(Wx::ListCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, [200, -1], wxLC_REPORT|wxLC_SINGLE_SEL|wxLC_VIRTUAL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, "Time");
    $self->InsertColumn(1, "Count");

    $self->SetColumnWidth(0, 200);

    $self->{_times} = [];
    $self->{_key_counts} = [];

    return $self;
}

sub OnGetItemText {
    my ($self, $index, $column) = @_;

    if ($column == 0) {
        return iso8601($self->{_times}[$index]);
    }
    elsif ($column == 1) {
        return $self->{_key_counts}[$index];
    }
    else {
        return "?";
    }
}

sub SetTimes {
    my ($self, $times, $key_counts) = @_;

    $self->{_times} = $times;
    $self->{_key_counts} = $key_counts;
    $self->SetItemCount(scalar @$times);
    $self->Refresh;
    $self->SetItemState(0, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);
}

sub GetTime {
    my ($self, $index) = @_;

    return $self->{_times}[$index];
}


package KeyListCtrl;

use Wx qw(:everything);
use Wx::ArtProvider qw(:artid :clientid);

use base qw(Wx::ListCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, [200, -1], wxLC_REPORT|wxLC_SINGLE_SEL|wxLC_VIRTUAL|wxBORDER_SUNKEN);
    bless $self, $class;

    my $imagelist = Wx::ImageList->new(16, 16, 1);
    $imagelist->Add(Wx::ArtProvider::GetIcon(wxART_FOLDER, wxART_MENU, [16, 16]));
    $self->AssignImageList($imagelist, wxIMAGE_LIST_SMALL);

    $self->InsertColumn(0, "Key");

    $self->SetColumnWidth(0, 280);

    return $self;
}

sub OnGetItemText {
    my ($self, $index, $column) = @_;

    my $key = $self->{_keys}[$index];
    return if !defined $key;
    if ($column == 0) {
        my $key_path = $key->get_path;
        $key_path =~ s/\0/[NUL]/g;
        $key_path =~ s/\n/[LF]/g;
        $key_path =~ s/\r/[CR]/g;
        return $key_path;
    }
    else {
        return "?";
    }
}

sub OnGetItemImage {
    my ($self, $index) = @_;

    return 0;
}

sub SetKeys {
    my ($self, $keys) = @_;

    $self->{_keys} = $keys;
    $self->SetItemCount(scalar @$keys);
    $self->Refresh;
    $self->SetItemState(0, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);
}

sub GetKey {
    my ($self, $index) = @_;

    return $self->{_keys}[$index];
}


package TimelineDialog;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(Wx::Frame);

use constant ID_CLOSE_DIALOG => Wx::NewId;

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Timeline", wxDefaultPosition, [600, 300]);
    bless $self, $class;

    $self->SetMinSize([600, 300]);

    my $hsplitter = Wx::SplitterWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    my $list1 = TimeListCtrl->new($hsplitter);

    my $list2 = KeyListCtrl->new($hsplitter);

    $hsplitter->SplitVertically($list1, $list2);
    $hsplitter->SetMinimumPaneSize(10);

    $self->{_list1} = $list1;
    $self->{_list2} = $list2;

    my $accelerators = Wx::AcceleratorTable->new(
        [0, WXK_ESCAPE, ID_CLOSE_DIALOG],
        [wxACCEL_CTRL, ord('W'), ID_CLOSE_DIALOG],
    );
    $self->SetAcceleratorTable($accelerators);

    EVT_MENU($self, ID_CLOSE_DIALOG, \&OnClose);

    EVT_SPLITTER_DCLICK($self, $hsplitter, \&OnSplitterDClick);

    EVT_LIST_ITEM_SELECTED($self, $list1, \&OnTimeListItemSelected);

    EVT_CLOSE($self, \&OnClose);

    $self->SetIcon(Wx::GetWxPerlIcon());

    return $self;
}

sub OnSplitterDClick {
    my ($self, $event) = @_;

    $event->Veto;
}

sub OnTimeListItemSelected {
    my ($self, $event) = @_;

    my $index = $event->GetIndex;
    my $time = $self->{_list1}->GetTime($index);
    $self->{_list2}->SetKeys($self->{_keys_by_time}{$time});
}

sub OnKeyListItemActivated {
    my ($self, $event) = @_;

    $self->Close;
}

sub SetTimeline {
    my ($self, $keys_by_time) = @_;

    my @times = sort keys %$keys_by_time;
    my @key_counts = map { scalar @{$keys_by_time->{$_}} } @times;

    my $list1 = $self->{_list1};
    $list1->SetTimes(\@times, \@key_counts);

    my $list2 = $self->{_list2};
    $list2->SetKeys([]);

    $self->{_times} = \@times;
    $self->{_keys_by_time} = $keys_by_time;
}

sub OnClose {
    my ($self, $event) = @_;

    $self->Hide;
}


package ViewApp;

use Wx qw(:everything);

use base qw(Wx::App);

sub OnInit {
    my ($self) = @_;

    my $frame = ViewFrame->new(undef);
    $frame->Show;

    return 1;
}


package main;

my $app = ViewApp->new;
$app->MainLoop;
