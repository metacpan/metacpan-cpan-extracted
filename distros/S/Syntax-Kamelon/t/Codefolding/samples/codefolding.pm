package Syntax::Kamelon::Wx::PluggableTextCtrl;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use Wx qw( :textctrl :font :colour );
use Wx::DND;
use Wx qw( wxTheClipboard );
use base qw( Wx::TextCtrl );
use Wx::Event qw( EVT_CHAR );

require Syntax::Kamelon::Wx::PluggableTextCtrl::KeyEchoes;
require Syntax::Kamelon::Wx::PluggableTextCtrl::UndoRedo;
require Syntax::Kamelon::Wx::PluggableTextCtrl::Highlighter;

my $defaultfont = [10, wxFONTFAMILY_MODERN, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL, 0];

my $debug = 0;

if ($debug) {
   use Data::Dumper;
}

sub new {
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->{CALLBACK} = sub {};
   $self->{COMMANDS} = {
      'doremove' => \&DoRemove,
      'doreplace' => \&DoReplace,
      'dowrite' => \&DoWrite,
   };
   $self->{LISTENING} = 0;
   
   $self->{OVRMODE} = 0;
   $self->{PLUGINS} = [];

   $self->SetFont( Wx::Font->new(@$defaultfont) );
   EVT_CHAR($self, \&OnChar);

   return $self;
}

sub AppendText {
   my $self = shift;
   unless ($self->Broadcast('append', @_)) {
      $self->SUPER::Append(@_);
   }
}

sub Broadcast {
   my $self = shift;
   my $plugs = $self->{PLUGINS};
   my $flag = 0;
   foreach (@$plugs) {
      if ($_->Receive(@_)) {
         $flag = 1;
      }
   }
   return $flag;
}

sub Call2Remove {
   my ($self, $call, $index, $txt) = @_;
   if ($call =~ /.*remove$/) {
      return ($index, $index + length($txt))
   } else {
      carp "Call '$call' is not a remove type";
      return undef
   }
}

sub Call2Replace {
   my ($self, $call, $index, $old, $txt, $sel) = @_;
   if ($call =~ /.*replace$/) {
      return ($index, $index + length($old), $txt)
   } else {
      carp "Call '$call' is not a replace type";
      return undef
   }
}

sub Call2WriteText {
   my ($self, $call, $index, $txt) = @_;
   if ($call =~ /.*write$/) {
      return $txt
   } else {
      carp "Call '$call' is not a write type";
      return undef
   }
}

sub Callback {
   my $self = shift;
   if (@_) { $self->{CALLBACK} = shift; }
   return $self->{CALLBACK};
}

sub CanUndo {
   my $self = shift;
   return $self->Broadcast('canundo');
}

sub CanRedo {
   my $self = shift;
   return $self->Broadcast('canredo');
}

sub Clear {
   my $self = shift;
   unless ($self->Broadcast('clear')) {
      $self->SUPER::Clear;
   }
}

sub ClearSelection {
   my $self = shift;
   my $ins = $self->GetInsertionPoint;
   $self->SetSelection($ins, $ins);
}

sub Command {
   my $self = shift;
   my $name = shift;
   if (@_) { $self->{COMMANDS}->{$name} = shift }
   return $self->{COMMANDS}->{$name}
}

sub Copy {
   my $self = shift;
   unless ($self->Broadcast('copy')) {
      $self->SUPER::Copy;
   }
}

sub Cut {
   my $self = shift;
   unless ($self->Broadcast('cut')) {
      $self->SUPER::Cut;
   }
}

sub DoRemove {
   my $self = shift;
   my ($index, $txt, $sel, $ins) = @_;
   $self->ClearSelection;
   $self->SUPER::Remove($index, $index + length($txt));
   if (defined($ins)) {
      $self->SetInsertionPoint($ins);
   }
   return 1
}

sub DoReplace {
   my ($self, $index, $old, $txt, $sel, $ins) = @_;
   $self->ClearSelection;
   $self->SUPER::Replace($index, $index + length($old), $txt);
   if ($sel) {
      $self->SetSelection($index, $index + length($txt));
   }
   if (defined($ins)) {
      $self->SetInsertionPoint($ins);
   }
   return 1
}

sub DoWrite {
   my ($self, $index, $txt, $sel, $ins) = @_;
   $self->ClearSelection;
   $self->SetInsertionPoint($index);
   $self->SUPER::WriteText($txt);
   if ($sel) {
      $self->SetSelection($index, $index + length($txt));
   }
   if (defined($ins)) {
      $self->SetInsertionPoint($ins);
   }
   return 1
}

sub FindPluginId {
   my ($self, $name) = @_;
   my $plgs = $self->{PLUGINS};
   my $index = 0;
   foreach (@$plgs) {
      if ($name eq $plgs->[$index]->Name) {
         return $index
      }
      $index ++;
   }
#   carp "Plugin $name is not loaded\n";
   return undef;
}

sub FindPlugin {
   my ($self, $name) = @_;
   my $plgs = $self->{PLUGINS};
   foreach (@$plgs) {
      if ($name eq $_->Name) {
			return $_
      }
   }
   return undef;
}

sub GetClipboardText {
   my $self = shift;
   my $txt = undef;
   if (wxTheClipboard->Open) {
      if ($debug) { print "Clipboard open\n" }
      my $textdata = Wx::TextDataObject->new;
      my $ok = wxTheClipboard->GetData( $textdata );
      if( $ok ) {
         $txt = $textdata->GetText;
      }
      if ($debug and defined($txt)) { print "Clipboard text: $txt\n" }
      wxTheClipboard->Close;
   }
   return $txt;
}

sub GetLineNumber {
   my ($self, $index) = @_;
   unless (defined($index)) { $index = $self->GetInsertionPoint };
   my ($col, $line) = $self->PositionToXY($index);
   return $line;
}

sub HasSelection {
   my $self = shift;
   my ($selb, $sele) = $self->GetSelection;
   return ($selb ne $sele)
}

# TODO make this unicode compatible
sub IsWriteable {
   my ($self, $key) = @_;
   if ((($key >= 32) and ($key < 127)) or (($key > 127) and ($key < 256))) {
      return 1
   }
   return 0
}

sub Listening {
   my $self = shift;
   if (@_) {
      my $new = shift;
      unless ($new eq $self->{LISTENING}) {
         my $plgs = $self->{PLUGINS};
         if ($new) {
            unshift @$plgs, $self
         } else {
            shift @$plgs
         }
         $self->{LISTENING} = $new
      }
   }
   return $self->{LISTENING}
}

sub LoadFile {
   my $self = shift;
   unless ($self->Broadcast('load', @_)) {
      $self->SUPER::LoadFile(@_);
   }
}

sub LoadPlugin {
   my $self = shift;
	my $plug = undef;
	my $name = shift;
	#Does anybody have a better idea for this?
	$name = "Syntax::Kamelon::Wx::PluggableTextCtrl::$name";
	$plug = $name->new($self, @_);
	if (defined($plug)) {
		$self->RegisterPlugin($plug);
	} else {
		carp "unable to load plugin $name\n";
	}
}

sub Name {
   my $self = shift;
   my $name = ref $self;
   $name =~s/.*:://;
   if ($debug) { print "plugin name is $name\n" }
   return $name
}

sub OnChar {
   my ($self, $event) = @_;
   my $k = $event->GetKeyCode;
   if ($k eq 322) { #Insert key pressed, record flip insert/ovr mode.
      if ($self->OvrMode) {
         $self->OvrMode(0)
      } else {
         $self->OvrMode(1)
      }
   }
   unless ($self->Broadcast('key', $event)) {
      $event->Skip;
   }
   my $callback = $self->Callback;
   &$callback;
}

sub OvrMode {
   my $self = shift;
   if (@_) { $self->{OVRMODE} = shift; }
   return $self->{OVRMODE};
}

sub Paste {
   my $self = shift;
   unless ($self->Broadcast('paste')) {
      $self->SUPER::Paste;
   }
}

sub Plugin {
   my $self = shift;
   my $id = shift;
   my $plgs = $self->{PLUGINS};
   unless ($id =~ /^\d+$/) {
      $id = $self->FindPluginId($id);
   }
   if (@_) { 
      $self->{PLUGINS}->[$id] = shift; 
   }
   return $self->{PLUGINS}->[$id];
}

sub Receive {
   my $self = shift;
   my $name = shift;
#    if ($debug) { print "received $name\n"; print Dumper $self->{COMMANDS} }
   if (exists $self->{COMMANDS}->{$name}) {
      if ($debug) { print "executing $name\n" }
      my $cmd = $self->Command($name);
      return &$cmd($self, @_);
   }
   return 0
}

sub Redo {
   my $self = shift;
   unless ($self->Broadcast('redo')) {
      $self->SUPER::Redo;
   }
}

sub RegisterPlugin {
   my ($self, $plug) = @_;
   my $pl = $self->{PLUGINS};
   push @$pl, $plug;
}

sub Remove {
   my $self = shift;
   my @call = $self->Remove2Call(@_);
   unless ($self->Broadcast(@call)) {
      $self->SUPER::Remove(@_);
   }
}

sub Remove2Call {
   my ($self, $begin, $end) = @_;
   my $sel = 0;
   my ($selb, $sele) = $self->GetSelection;
   if (($selb eq $begin) and ($sele eq $end)) { $sel = 1 }
   return ('remove', $begin, $self->GetRange($begin, $end), $sel)
}

sub Replace {
   my $self = shift;
   my @call = $self->Replace2Call(@_);
   unless ($self->Broadcast(@call)) {
      $self->SUPER::Replace(@_);
   }
}

sub Replace2Call {
   my ($self, $begin, $end, $txt) = @_;
   my $sel = 0;
   my ($selb, $sele) = $self->GetSelection;
   if (($selb eq $begin) and ($sele eq $end)) { $sel = 1 }
   return ('replace', $begin, $txt, $self->GetRange($begin, $end), $sel)
}

sub SaveFile {
   my $self = shift;
   unless ($self->Broadcast('save', @_)) {
      $self->SUPER::SaveFile(@_);
   }
}

sub NativePlugins {
   my $self = shift;
   return qw[ Highlighter KeyEchoes UndoRedo   ]
}

sub Syntax {
   my $self = shift;
   return $self->Broadcast('syntax', @_);
}

sub Undo {
   my $self = shift;
   unless ($self->Broadcast('undo')) {
      $self->SUPER::Undo;
   }
}

sub WriteText {
   my $self = shift;
   my @call = $self->WriteText2Call(@_);
   unless ($self->Broadcast(@call)) {
      $self->SUPER::WriteText(@_);
   }
}

sub WriteText2Call {
   my ($self, $txt) = @_;
   return ('write', $self->GetInsertionPoint, $txt, 0);
}


1;
__END__
