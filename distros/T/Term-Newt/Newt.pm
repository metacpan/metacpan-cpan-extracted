package Term::Newt;

# $Id: Newt.pm,v 1.4 1998/11/09 02:31:44 daniel Exp daniel $

use strict;
use Exporter;
use DynaLoader;
use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Term::Newt::AL Exporter DynaLoader);
@EXPORT = qw(
	H_NEWT
	NEWT_ANCHOR_BOTTOM NEWT_ANCHOR_LEFT NEWT_ANCHOR_RIGHT NEWT_ANCHOR_TOP
	NEWT_COLORSET_ACTBUTTON NEWT_COLORSET_ACTCHECKBOX NEWT_COLORSET_ACTLISTBOX
	NEWT_COLORSET_ACTSELLISTBOX NEWT_COLORSET_ACTTEXTBOX NEWT_COLORSET_BORDER
	NEWT_COLORSET_BUTTON NEWT_COLORSET_CHECKBOX NEWT_COLORSET_COMPACTBUTTON
	NEWT_COLORSET_DISENTRY NEWT_COLORSET_EMPTYSCALE NEWT_COLORSET_ENTRY
	NEWT_COLORSET_FULLSCALE NEWT_COLORSET_HELPLINE NEWT_COLORSET_LABEL
	NEWT_COLORSET_LISTBOX NEWT_COLORSET_ROOT NEWT_COLORSET_ROOTTEXT
	NEWT_COLORSET_SELLISTBOX NEWT_COLORSET_SHADOW NEWT_COLORSET_TEXTBOX
	NEWT_COLORSET_TITLE NEWT_COLORSET_WINDOW NEWT_ENTRY_DISABLED NEWT_ENTRY_HIDDEN
	NEWT_ENTRY_RETURNEXIT NEWT_ENTRY_SCROLL NEWT_FD_READ NEWT_FD_WRITE 
	NEWT_FLAG_DISABLED NEWT_FLAG_DOBORDER NEWT_FLAG_HIDDEN NEWT_FLAG_MULTIPLE
	NEWT_FLAG_NOF12 NEWT_FLAG_NOSCROLL NEWT_FLAG_RETURNEXIT NEWT_FLAG_SCROLL
	NEWT_FLAG_SELECTED NEWT_FLAG_WRAP NEWT_FORM_NOF12 NEWT_GRID_FLAG_GROWX
	NEWT_GRID_FLAG_GROWY NEWT_KEY_BKSPC NEWT_KEY_DELETE NEWT_KEY_DOWN NEWT_KEY_END
	NEWT_KEY_ENTER NEWT_KEY_EXTRA_BASE NEWT_KEY_F1 NEWT_KEY_F10 NEWT_KEY_F11
	NEWT_KEY_F12 NEWT_KEY_F2 NEWT_KEY_F3 NEWT_KEY_F4 NEWT_KEY_F5 NEWT_KEY_F6
	NEWT_KEY_F7 NEWT_KEY_F8 NEWT_KEY_F9 NEWT_KEY_HOME NEWT_KEY_LEFT NEWT_KEY_PGDN
	NEWT_KEY_PGUP NEWT_KEY_RESIZE NEWT_KEY_RETURN NEWT_KEY_RIGHT NEWT_KEY_SUSPEND
	NEWT_KEY_TAB NEWT_KEY_UNTAB NEWT_KEY_UP NEWT_LISTBOX_RETURNEXIT NEWT_TEXTBOX_SCROLL
	NEWT_TEXTBOX_WRAP
	NULL
);

$VERSION = '0.01';

bootstrap Term::Newt $VERSION;

sub new {
	my $proto = shift;
	bless my $self = {}, (ref $proto || $proto);

	$self->{'init'} = 0;
	$self;
}

sub DESTROY {
	my $self = shift;
	$self->finished;
}

sub init {
	my $self = shift;
	$self->newtInit;
	$self->{'init'} = 1;
}

sub cls {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtCls;
}

sub draw_root_text {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($c,$r,$text) = @_;
	$self->newtDrawRootText($c,$r,$text);
}

sub open_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($c,$r,$w,$h,$text) = @_;
	$self->newtOpenWindow($c,$r,$w,$h,$text);
}

sub refresh {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtRefresh;
}

sub finished {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtFinished;
	$self->{'init'} = 0;
}

sub form_add_components {
	my $self = shift;
	my $form = shift;
	return if $self->{'init'} <= 0;
	for (@_) {
		$self->newtFormAddComponent($form,$_);
	}
}

sub resize_screen {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $redraw = shift;
	$self->newtResizeScreen($redraw);
}

sub wait_for_key {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtWaitForKey;
}

sub clear_key_buffer {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtClearKeyBuffer;
}

sub delay {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $usecs = shift;
	$self->newtDelay($usecs);
}

sub centered_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($width,$height,$title) = @_;
	$self->newtCenteredWindow($width,$height,$title);
}

sub pop_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtPopWindow;
}

sub suspend {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtSuspend;
}

sub resume {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtSuspend;
}

sub push_help_line {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $text = shift;
	$self->newtPushHelpLine($text);
}

sub redraw_help_line {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtRedrawHelpLine;
}

sub pop_help_line {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtPopHelpLine;
}

sub bell {
	my $self = shift;
	return if $self->{'init'} <= 0;
	$self->newtBell;
}

sub compact_button {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text) = @_;
	$self->newtCompactButton($left,$top,$text);
}

sub button {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text) = @_;
	$self->newtButton($left,$top,$text);
}

sub checkbox {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text,$default,$seq,$result) = @_;
	$self->newtCheckbox($left,$top,$text,$default,$seq,$result);
}

sub checkbox_get_value {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $co = shift;
	$self->newtCheckboxGetValue($co);
}

sub radiobutton {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text,$is_default,$prev_button) = @_;
	$self->newtRadiobutton($left,$top,$text,$is_default,$prev_button);
}

sub radio_get_current {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $set_member = shift;
	$self->newtRadioGetCurrent($set_member);
}

sub listitem {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text,$is_default,$prev_item,$data,$flags) = @_;
	$self->newtListitem($left,$top,$text,$is_default,$prev_item,$data,$flags);
}

sub listitem_set {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$text) = @_;
	$self->newtListitemSet($co,$text);
}

sub listitem_get_data {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $co = shift;
	$self->newtListitemGetData($co);
}

sub get_screen_size {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($cols,$rows) = @_;
	$self->newtGetScreenSize($cols,$rows);
}

sub label {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text) = @_;
	$self->newtLabel($left,$top,$text);
}

sub label_set_text {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$text) = @_;
	$self->newtLabelSetText($co,$text);
}

sub vertical_scrollbar {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$height,$normal_colorset,$thumb_colorset) = @_;
	$self->newtVerticalScrollbar($left,$top,$height,$normal_colorset,$thumb_colorset);
}

sub scrollbar_set {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$where,$total) = @_;
	$self->newtScrollbarSet($co,$where,$total);
}

sub listbox {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$height,$flags) = @_;
	$self->newtListbox($left,$top,$height,$flags);
}

sub listbox_get_current {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my $co = shift;
	$self->newtListboxGetCurrent($co);
}

sub listbox_set_current {
	my $self = shift;
	return if $self->{'init'} <= 0;	
	my ($co,$num) = @_;
	$self->newtListboxSetCurrent($co,$num);
}

sub listbox_set_current_by_key {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$key) = @_;
	$self->newtListboxSetCurrentByKey($co,$key);
}

sub listbox_set_text {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$num,$text) = @_;
	$self->newtListboxSetText($co,$num,$text);
}

sub listbox_set_entry {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$num,$text) = @_;
	$self->newtListboxSetEntry($co,$num,$text);
}

sub listbox_set_width {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$width) = @_;
	$self->newtListboxSetWidth($co,$width);
}

sub listbox_set_data {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$num,$data) = @_;
	$self->newtListboxSetData($co,$num,$data);
}

sub listbox_add_entry {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$text,$data) = @_;
	$self->newtListboxAddEntry($co,$text,$data);
}

sub listbox_insert_entry {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$text,$data,$key) = @_;
	$self->newtListboxInsertEntry($co,$text,$data,$key);
}

sub listbox_delete_entry {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$data) = @_;
	$self->newtListboxDeleteEntry($co,$data);
}

sub listbox_clear {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtListboxClear($co);
}

sub listbox_clear_selection {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtListboxClearSelection($co);
}

sub textbox_reflowed {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$text,$width,$flex_down,$flex_up,$flags) = @_;
	$self->newtTextboxReflowed($left,$top,$text,$width,$flex_down,$flex_up,$flags);
}

sub textbox {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$width,$height,$flags) = @_;
	$self->newtTextbox($left,$top,$width,$height,$flags);
}

sub textbox_set_text {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$text) = @_;
	$self->newtTextboxSetText($co,$text);
}

sub textbox_set_height {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$height) = @_;
	$self->newtTextboxSetHeight($co,$height);
}

sub textbox_get_num_lines {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtTextboxGetNumLines($co);
}

sub reflow_text {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($text,$width,$flex_down,$flex_up,$actual_width,$actual_height) = @_;
	$self->newtReflowText($text,$width,$flex_down,$flex_up,$actual_width,$actual_height);
}

sub form {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($vert_bar,$help,$flags) = @_;
	$self->newtForm($vert_bar,$help,$flags);
}

sub form_watch_fd {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($form,$fd,$fd_flags) = @_;
	$self->newtFormWatchFd($form,$fd,$fd_flags);
}

sub form_set_size {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtFormSetSize($co);
}

sub form_get_current {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtFormGetCurrent($co);
}

sub form_set_background {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$color) = @_;
	$self->newtFormSetBackground($co,$color);
}

sub form_set_current {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$subco) = @_;
	$self->newtFormSetCurrent($co,$subco);
}

sub form_add_component {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($form,$co) = @_;
	$self->newtFormAddComponent($form,$co);
}

sub form_set_height {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$height) = @_;
	$self->newtFormSetHeight($co,$height);
}

sub form_set_width {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$width) = @_;
	$self->newtFormSetWidth($co,$width);
}

sub run_form {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($form) = @_;
	$self->newtRunForm($form);
}

sub draw_form {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($form) = @_;
	$self->newtDrawForm($form);
}

sub form_add_hot_key {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$key) = @_;
	$self->newtFormAddHotKey($co,$key);
}

sub entry {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$initial_value,$width,$result_ptr,$flags) = @_;
	$self->newtEntry($left,$top,$initial_value,$width,$result_ptr,$flags);
}

sub entry_set {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$value,$cursor_at_end) = @_;
	$self->newtEntrySet($co,$value,$cursor_at_end);
}

sub entry_set_filter {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$filter,$data) = @_;
	$self->newtEntrySetFilter($co,$filter,$data);
}

sub entry_get_value {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co) = @_;
	$self->newtEntryGetValue($co);
}

sub scale {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($left,$top,$width,$full_value) = @_;
	$self->newtScale($left,$top,$width,$full_value);
}

sub component_add_callback {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$f,$data) = @_;
	$self->newtComponentAddCallback($co,$f,$data);
}

sub component_takes_focus {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($co,$val) = @_;
	$self->newtComponentTakesFocus($co,$val);
}

sub form_destroy {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($form) = @_;
	$self->newtFormDestroy($form);
}

sub create_grid {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($cols,$rows) = @_;
	$self->newtCreateGrid($cols,$rows);
}

sub grid_vStacked {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($type,$what,@args) = @_;
	$self->newtGridVStacked($type,$what,@args);
}

sub grid_vClose_stacked {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($type,$what,@args) = @_;
	$self->newtGridVCloseStacked($type,$what,@args);
}

sub grid_hStacked {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($type1,$what1,@args) = @_;
	$self->newtGridHStacked($type1,$what1,@args);
}

sub grid_hClose_stacked {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($type1,$what1,@args) = @_;
	$self->newtGridHCloseStacked($type1,$what1,@args);
}

sub grid_basic_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($text,$middle,$buttons) = @_;
	$self->newtGridBasicWindow($text,$middle,$buttons);
}

sub grid_simple_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($text,$middle,$buttons) = @_;
	$self->newtGridSimpleWindow($text,$middle,$buttons);
}

sub grid_set_field {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$col,$row,$type,$val,$pad_left,$pad_top,$pad_right,$pad_bottom,$anchor,$flags) = @_;
	$self->newtGridSetField($grid,$col,$row,$type,$val,$pad_left,$pad_top,$pad_right,$pad_bottom,$anchor,$flags);
}

sub grid_place {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$left,$top) = @_;
	$self->newtGridPlace($grid,$left,$top);
}

sub grid_free {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$recurse) = @_;
	$self->newtGridFree($grid,$recurse);
}

sub grid_get_size {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$width,$height) = @_;
	$self->newtGridGetSize($grid,$width,$height);
}

sub grid_wrapped_window {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$title) = @_;
	$self->newtGridWrappedWindow($grid,$title);
}

sub grid_wrapped_window_at {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$title,$left,$top) = @_;
	$self->newtGridWrappedWindowAt($grid,$title,$left,$top);
}

sub grid_add_components_to_form {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($grid,$form,$recurse) = @_;
	$self->newtGridAddComponentsToForm($grid,$form,$recurse);
}

sub button_barv {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($button1,$b1comp,$args) = @_;
	$self->newtButtonBarv($button1,$b1comp,$args);
}

sub button_bar {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($button1,$b1comp,@args) = @_;
	$self->newtButtonBar($button1,$b1comp,@args);
}

sub win_message {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($title,$button_text,$text,@args) = @_;
	$self->newtWinMessage($title,$button_text,$text,@args);
}

sub win_messagev {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($title,$button_text,$text,$argv) = @_;
	$self->newtWinMessagev($title,$button_text,$text,$argv);
}

sub win_choice {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($title,$button1,$button2,$text,@args) = @_;
	$self->newtWinChoice($title,$button1,$button2,$text,@args);
}

sub win_ternary {
	my $self = shift;
	return if $self->{'init'} <= 0;
	my ($title,$button1,$button2,$button3,$message,@args) = @_;
	$self->newtWinTernary($title,$button1,$button2,$button3,$message,@args);
}


package Term::Newt::AL;
use Carp;
no strict;

# Cheap way out.
$SIG{'__WARN__'} = sub { warn $_[0] unless $_[0] =~ /Use of inherited AUTOLOAD/ };

sub AUTOLOAD {
	$AUTOLOAD =~ s/.*:://;
	my $val = Term::Newt::XS::constant($AUTOLOAD, $_[0] ? $_[0] : 0);

	if (!$!) {
		eval "sub $AUTOLOAD { $val }";
		goto &$AUTOLOAD;
	}

	if (exists $Term::Newt::XS::{"$AUTOLOAD"}) {
		$val = "Term::Newt::XS::$AUTOLOAD";
	} else {
		croak "Cannot do '$AUTOLOAD' in Term::Newt";
	}

	local $^W = 0;
	*$AUTOLOAD = sub { shift; &$val(@_); };
	goto &$AUTOLOAD;
}

1;
__END__

=head1 NAME

Term::Newt - Interface to the Newt text windowing library.

=head1 SYNOPSIS

use Term::Newt;

my $n = Term::Newt->new;

=head1 DESCRIPTION

This is an interface to the Newt text windowing library, which itself is built
on top of S-Lang.

*** THIS IS ALPHA SOFTWARE, USE AT YOUR OWN RISK.
*** THERE IS NO DOCUMENTATION YET.
*** THE INTERFACE MAY CHANGE!

=head1 Exported constants

  H_NEWT
  NEWT_ANCHOR_BOTTOM
  NEWT_ANCHOR_LEFT
  NEWT_ANCHOR_RIGHT
  NEWT_ANCHOR_TOP
  NEWT_COLORSET_ACTBUTTON
  NEWT_COLORSET_ACTCHECKBOX
  NEWT_COLORSET_ACTLISTBOX
  NEWT_COLORSET_ACTSELLISTBOX
  NEWT_COLORSET_ACTTEXTBOX
  NEWT_COLORSET_BORDER
  NEWT_COLORSET_BUTTON
  NEWT_COLORSET_CHECKBOX
  NEWT_COLORSET_COMPACTBUTTON
  NEWT_COLORSET_DISENTRY
  NEWT_COLORSET_EMPTYSCALE
  NEWT_COLORSET_ENTRY
  NEWT_COLORSET_FULLSCALE
  NEWT_COLORSET_HELPLINE
  NEWT_COLORSET_LABEL
  NEWT_COLORSET_LISTBOX
  NEWT_COLORSET_ROOT
  NEWT_COLORSET_ROOTTEXT
  NEWT_COLORSET_SELLISTBOX
  NEWT_COLORSET_SHADOW
  NEWT_COLORSET_TEXTBOX
  NEWT_COLORSET_TITLE
  NEWT_COLORSET_WINDOW
  NEWT_ENTRY_DISABLED
  NEWT_ENTRY_HIDDEN
  NEWT_ENTRY_RETURNEXIT
  NEWT_ENTRY_SCROLL
  NEWT_FD_READ
  NEWT_FD_WRITE
  NEWT_FLAG_DISABLED
  NEWT_FLAG_DOBORDER
  NEWT_FLAG_HIDDEN
  NEWT_FLAG_MULTIPLE
  NEWT_FLAG_NOF12
  NEWT_FLAG_NOSCROLL
  NEWT_FLAG_RETURNEXIT
  NEWT_FLAG_SCROLL
  NEWT_FLAG_SELECTED
  NEWT_FLAG_WRAP
  NEWT_FORM_NOF12
  NEWT_GRID_FLAG_GROWX
  NEWT_GRID_FLAG_GROWY
  NEWT_KEY_BKSPC
  NEWT_KEY_DELETE
  NEWT_KEY_DOWN
  NEWT_KEY_END
  NEWT_KEY_ENTER
  NEWT_KEY_EXTRA_BASE
  NEWT_KEY_F1
  NEWT_KEY_F10
  NEWT_KEY_F11
  NEWT_KEY_F12
  NEWT_KEY_F2
  NEWT_KEY_F3
  NEWT_KEY_F4
  NEWT_KEY_F5
  NEWT_KEY_F6
  NEWT_KEY_F7
  NEWT_KEY_F8
  NEWT_KEY_F9
  NEWT_KEY_HOME
  NEWT_KEY_LEFT
  NEWT_KEY_PGDN
  NEWT_KEY_PGUP
  NEWT_KEY_RESIZE
  NEWT_KEY_RETURN
  NEWT_KEY_RIGHT
  NEWT_KEY_SUSPEND
  NEWT_KEY_TAB
  NEWT_KEY_UNTAB
  NEWT_KEY_UP
  NEWT_LISTBOX_RETURNEXIT
  NEWT_TEXTBOX_SCROLL
  NEWT_TEXTBOX_WRAP

=head1 AUTHOR

Daniel E<lt>daniel-cpan-newt@electricrain.comE<gt>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

newt(1), slang(1), perl(1)

=cut

