#!/usr/bin/perl
use strict;
use warnings;

binmode STDOUT, ':utf8';

use Parse::Win32Registry 0.60;


package BlockListCtrl;

use Wx qw(:everything);

use base qw(Wx::ListCtrl);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_SINGLE_SEL|wxLC_VIRTUAL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, "Block");
    $self->InsertColumn(1, "Length");
    $self->InsertColumn(2, "Tag");

    $self->SetColumnWidth(0, 100);
    $self->SetColumnWidth(2, 100);

    return $self;
}

sub Clear {
    my ($self) = @_;

    $self->{_blocks} = [];
    $self->SetItemCount(0);
    $self->Refresh;
}

sub OnGetItemText {
    my ($self, $index, $column) = @_;

    my $block = $self->{_blocks}[$index];
    return if !defined $block;
    if ($column == 0) {
        return sprintf '0x%x', $block->get_offset;
    }
    elsif ($column == 1) {
        return sprintf '0x%x', $block->get_length;
    }
    elsif ($column == 2) {
        return sprintf '%s', $block->get_tag;
    }
    else {
        return "?";
    }
}

sub SetRegistry {
    my ($self, $registry) = @_;

    $self->{_blocks} = [];
    my $block_iter = $registry->get_block_iterator;
    while (my $block = $block_iter->get_next) {
        push @{$self->{_blocks}}, $block;
    }
    $self->SetItemCount(scalar @{$self->{_blocks}});
    $self->Refresh;
    $self->SetItemState(0, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);
}

sub GetBlock {
    my ($self, $index) = @_;

    return $self->{_blocks}[$index];
}

sub GoToBlock {
    my ($self, $offset) = @_;

    my $index = 0;
    foreach my $block (@{$self->{_blocks}}) {
        my $block_start = $block->get_offset;
        my $block_end = $block_start + $block->get_length;
        if ($offset >= $block_start && $offset < $block_end) {
            $self->EnsureVisible($index);
            $self->SetItemState($index, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
            return;
        }
        $index++;
    }
}


package EntryListCtrl;

use Wx qw(:everything);

use base qw(Wx::ListCtrl);

use constant ATTR_KEY =>
    Wx::ListItemAttr->new(Wx::Colour->new('#000000'),
                          Wx::Colour->new('#ffb0b0'), wxNullFont);
use constant ATTR_VALUE =>
    Wx::ListItemAttr->new(Wx::Colour->new('#000000'),
                          Wx::Colour->new('#b0ffb0'), wxNullFont);
use constant ATTR_SECURITY =>
    Wx::ListItemAttr->new(Wx::Colour->new('#000000'),
                          Wx::Colour->new('#b0ffff'), wxNullFont);
use constant ATTR_SUBKEY_LIST =>
    Wx::ListItemAttr->new(Wx::Colour->new('#000000'),
                          Wx::Colour->new('#ffb0ff'), wxNullFont);
use constant ATTR_OTHER =>
    Wx::ListItemAttr->new(Wx::Colour->new('#000000'),
                          Wx::Colour->new('#f0f0f0'), wxNullFont);
#use constant ATTR_OTHER =>
#    Wx::ListItemAttr->new(wxNullColour, wxNullColour, wxNullFont);

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxLC_REPORT|wxLC_SINGLE_SEL|wxLC_VIRTUAL|wxBORDER_SUNKEN);
    bless $self, $class;

    $self->InsertColumn(0, "Entry");
    $self->InsertColumn(1, "Length");
    $self->InsertColumn(2, "Alloc.");
    $self->InsertColumn(3, "Tag");
    $self->InsertColumn(4, "Name");

    $self->SetColumnWidth(0, 100);
    $self->SetColumnWidth(3, 100);
    $self->SetColumnWidth(4, 200);

    return $self;
}

sub Clear {
    my ($self) = @_;

    $self->{_entries} = [];
    $self->SetItemCount(0);
    $self->Refresh;
}

sub OnGetItemText {
    my ($self, $index, $column) = @_;

    my $entry = $self->{_entries}[$index];
    return if !defined $entry;
    if ($column == 0) {
        return sprintf '0x%x', $entry->get_offset;
    }
    elsif ($column == 1) {
        return sprintf '0x%x', $entry->get_length;
    }
    elsif ($column == 2) {
        return $entry->is_allocated;
    }
    elsif ($column == 3) {
        return $entry->get_tag;
    }
    elsif ($column == 4) {
        my $name = '';
        if ($entry->can('get_name')) {
             $name = $entry->get_name;
             $name =~ s/\0/[NUL]/g;
             $name =~ s/\n/[LF]/g;
             $name =~ s/\r/[CR]/g;
        }
        return $name;
    }
    else {
        return "?";
    }
}

sub OnGetItemAttr {
    my ($self, $index) = @_;

    my $entry = $self->{_entries}[$index];
    return if !defined $entry;
    my $tag = $entry->get_tag;
    if ($tag eq 'nk' || $tag eq 'rgkn key' || $tag eq 'rgdb key') {
        return ATTR_KEY;
    }
    elsif ($tag eq 'vk' || $tag eq 'rgdb value') {
        return ATTR_VALUE;
    }
    elsif ($tag eq 'sk') {
        return ATTR_SECURITY;
    }
    elsif ($tag eq 'lh' || $tag eq 'lf' || $tag eq 'li' || $tag eq 'ri') {
        return ATTR_SUBKEY_LIST;
    }
    else {
        return ATTR_OTHER;
    }
}

sub SetBlock {
    my ($self, $block) = @_;

    $self->{_entries} = [];
    my $entry_iter = $block->get_entry_iterator;
    while (my $entry = $entry_iter->get_next) {
        push @{$self->{_entries}}, $entry;
    }
    $self->SetItemCount(scalar @{$self->{_entries}});
    $self->Refresh;
    $self->SetItemState(0, wxLIST_STATE_FOCUSED, wxLIST_STATE_FOCUSED);
}

sub GetEntry {
    my ($self, $index) = @_;

    return $self->{_entries}[$index];
}

sub GoToEntry {
    my ($self, $offset) = @_;

    my $index = 0;
    foreach my $entry (@{$self->{_entries}}) {
        my $entry_start = $entry->get_offset;
        my $entry_end = $entry_start + $entry->get_length;
        if ($offset >= $entry_start && $offset < $entry_end) {
            $self->EnsureVisible($index);
            $self->SetItemState($index, wxLIST_STATE_SELECTED, wxLIST_STATE_SELECTED);
            return;
        }
        $index++;
    }
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

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $sizer->Add($static, 0, wxEXPAND|wxALL, 5);
    $sizer->Add($text, 0, wxEXPAND|wxALL, 5);

    my $button_sizer = $self->CreateSeparatedButtonSizer(wxOK|wxCANCEL);

    $sizer->Add($button_sizer, 0, wxEXPAND|wxALL, 5);

    $self->SetSizer($sizer);

    $self->{_text} = $text;

    $self->Fit; # resizes dialog to best fit child windows

    $self->{_text}->SetFocus;
    $self->SetFocus;

    return $self;
}

sub GetText {
    my ($self) = @_;

    return $self->{_text}->GetValue;
}

sub SetText {
    my ($self, $value) = @_;

    $value = '' if !defined $value;
    $self->{_text}->ChangeValue($value);
    $self->{_text}->SetSelection(-1, -1);
}


package ScopeFrame;

use Encode;
use File::Basename;
use FindBin;
use Parse::Win32Registry;
use Wx qw(:everything);
use Wx::Event qw(:everything);

use base qw(Wx::Frame);

use constant ID_FIND_NEXT => Wx::NewId;
use constant ID_SELECT_FONT => Wx::NewId;
use constant ID_GO_TO => Wx::NewId;

sub new {
    my ($class, $parent) = @_;

    my $self = $class->SUPER::new($parent, -1, "Registry Scope", wxDefaultPosition, [600, 400]);
    bless $self, $class;

    $self->SetMinSize([600, 400]);

    my $menu1 = Wx::Menu->new;
    $menu1->Append(wxID_OPEN, "&Open...\tCtrl+O");
    $menu1->Append(wxID_CLOSE, "&Close\tCtrl+W");
    $menu1->AppendSeparator;
    $menu1->Append(wxID_EXIT, "E&xit\tAlt+F4");

    my $menu2 = Wx::Menu->new;
    $menu2->Append(wxID_FIND, "&Find...\tCtrl+F");
    $menu2->Append(ID_FIND_NEXT, "Find &Next\tF3");
    $menu2->AppendSeparator;
    $menu2->Append(ID_GO_TO, "&Go To Offset...\tCtrl+G");

    my $menu3 = Wx::Menu->new;
    $menu3->Append(ID_SELECT_FONT, "Select &Font...");

    my $menu4 = Wx::Menu->new;
    $menu4->Append(wxID_ABOUT, "&About...");

    my $menubar = Wx::MenuBar->new;
    $menubar->Append($menu1, "&File");
    $menubar->Append($menu2, "&Search");
    $menubar->Append($menu3, "&View");
    $menubar->Append($menu4, "&Help");

    $self->SetMenuBar($menubar);

    my $statusbar = Wx::StatusBar->new($self, -1);
    $self->SetStatusBar($statusbar);

    EVT_MENU($self, wxID_OPEN, \&OnOpenFile);
    EVT_MENU($self, wxID_CLOSE, \&OnCloseFile);
    EVT_MENU($self, wxID_EXIT, \&OnQuit);
    EVT_MENU($self, wxID_FIND, \&OnFind);
    EVT_MENU($self, ID_FIND_NEXT, \&FindNext);
    EVT_MENU($self, ID_GO_TO, \&GoToOffset);
    EVT_MENU($self, wxID_ABOUT, \&OnAbout);
    EVT_MENU($self, ID_SELECT_FONT, \&OnSelectFont);

    my $vsplitter = Wx::SplitterWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    my $text = Wx::TextCtrl->new($vsplitter, -1, '', wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE|wxTE_DONTWRAP|wxTE_READONLY);
    $text->SetFont(Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL));

    my $hsplitter = Wx::SplitterWindow->new($vsplitter, -1, wxDefaultPosition, wxDefaultSize, wxSP_NOBORDER);

    $vsplitter->SplitHorizontally($hsplitter, $text);
    $vsplitter->SetMinimumPaneSize(10);

    my $list1 = BlockListCtrl->new($hsplitter);

    my $list2 = EntryListCtrl->new($hsplitter);

    $hsplitter->SplitVertically($list1, $list2);
    $hsplitter->SetMinimumPaneSize(10);

    $self->{_list1} = $list1;
    $self->{_list2} = $list2;
    $self->{_vsplitter} = $vsplitter;
    $self->{_text} = $text;
    $self->{_statusbar} = $statusbar;

    EVT_SPLITTER_DCLICK($self, $hsplitter, \&OnSplitterDClick);
    EVT_SPLITTER_DCLICK($self, $vsplitter, \&OnSplitterDClick);

    EVT_LIST_ITEM_SELECTED($self, $list1, \&OnBlockSelected);
    EVT_LIST_ITEM_SELECTED($self, $list2, \&OnEntrySelected);

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

sub GoToOffset {
    my ($self, $event) = @_;

    return if !defined $self->{_registry};

    my $dialog = Wx::TextEntryDialog->new($self, 'Enter the offset below:', 'Go To Offset', '0x');
    if ($dialog->ShowModal != wxID_OK) {
        return;
    }

    my $offset;
    eval {
        my $answer = $dialog->GetValue;
        if ($answer =~ m/^\s*0x[\da-fA-F]+\s*$/ || $answer =~ m/^\s*\d+\s*$/) {
            $offset = int(eval $answer);
        }
    };

    $dialog->Destroy;

    if (defined $offset) {
        $self->{_list1}->GoToBlock($offset);
        $self->{_list2}->GoToEntry($offset);
    }

    $self->{_list2}->SetFocus;
    $self->SetFocus;
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

sub OnBlockSelected {
    my ($self, $event) = @_;

    my $index = $event->GetIndex;
    my $block = $self->{_list1}->GetBlock($index);

    $self->{_list2}->SetBlock($block);

    my $parse_info = $block->parse_info;
    $parse_info =~ s/\0/[NUL]/g;
    $parse_info =~ s/\n/[LF]/g;
    $parse_info =~ s/\r/[CR]/g;
    my $details = $parse_info . "\n" . $block->unparsed;

    $self->{_text}->ChangeValue($details);

    my $status = sprintf "Block Offset: 0x%x", $block->get_offset;
    $self->{_statusbar}->SetStatusText($status);
}

sub OnEntrySelected {
    my ($self, $event) = @_;

    my $index = $event->GetIndex;
    my $entry = $self->{_list2}->GetEntry($index);

    my $parse_info = $entry->parse_info;
    $parse_info =~ s/\0/[NUL]/g;
    $parse_info =~ s/\n/[LF]/g;
    $parse_info =~ s/\r/[CR]/g;
    my $details = $parse_info . "\n" . $entry->unparsed;

    $self->{_text}->ChangeValue($details);

    my $status = sprintf "Entry Offset: 0x%x", $entry->get_offset;
    $self->{_statusbar}->SetStatusText($status);
}

sub OnAbout {
    my ($self, $event) = @_;

    my $info = Wx::AboutDialogInfo->new;
    $info->SetName($FindBin::Script);
    $info->SetVersion($Parse::Win32Registry::VERSION);
    $info->SetCopyright('Copyright (c) 2010-2012 James Macfarlane');
    $info->SetDescription('wxWidgets Registry Scope for the Parse::Win32Registry module');
    Wx::AboutBox($info);
}

sub OnFind {
    my ($self, $event) = @_;

    return if !defined $self->{_registry};

    my $dialog = FindDialog->new($self);
    $dialog->SetText($self->{_find_param});
    if ($dialog->ShowModal == wxID_OK) {
        my $registry = $self->{_registry};
        my $find_iter = $registry->get_entry_iterator;
        $self->{_find_param} = $dialog->GetText;
        $self->{_find_iter} = $find_iter;
        $self->FindNext;
    }
    $dialog->Destroy;
}

sub FindNext {
    my ($self) = @_;

    my $find_param = $self->{_find_param};
    my $find_iter = $self->{_find_iter};

    return if !defined $find_param || $find_param eq '';
    return if !defined $find_iter;

    my $start = time;

    my $max = 0;
    my $progress_dialog;

    my $iter_finished = 1;

    while (my $entry = $find_iter->get_next) {
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
            $self->{_list1}->GoToBlock($entry->get_offset);
            $self->{_list2}->GoToEntry($entry->get_offset);
            $iter_finished = 0;
            last;
        }

        if (defined $progress_dialog) {
            if (!$progress_dialog->Update) {
                # Cancelled!
                $iter_finished = 0;
                last;
            }
        }
        else {
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
    $self->{_list1}->SetFocus;
    $self->SetFocus;
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

    # clear
    $self->OnCloseFile;

    # set up
    $self->{_registry} = $registry;
    $self->{_list1}->SetRegistry($registry);
    $self->{_list1}->SetFocus;
    $self->SetTitle("$basename - Registry Scope");
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

    $self->{_list1}->Clear;
    $self->{_list2}->Clear;
    $self->{_text}->Clear;
    $self->{_registry} = undef;
    $self->{_find_iter} = undef;
    $self->SetTitle("Registry Scope");
}

sub OnQuit {
    my ($self) = @_;

    $self->Close;
}


package ScopeApp;

use Wx qw(:everything);

use base qw(Wx::App);

sub OnInit {
    my ($self) = @_;

    my $frame = ScopeFrame->new(undef);
    $frame->Show;

    return 1;
}


package main;

my $app = ScopeApp->new;
$app->MainLoop;
