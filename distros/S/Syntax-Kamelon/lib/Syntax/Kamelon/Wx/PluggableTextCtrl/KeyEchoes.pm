package Syntax::Kamelon::Wx::PluggableTextCtrl::KeyEchoes;

use strict;
use warnings;
use Carp;

use Wx qw( wxMOD_SHIFT );
use base qw( Syntax::Kamelon::Wx::PluggableTextCtrl::BasePlugin );

my $debug = 1;

if ($debug) {
   use Data::Dumper;
}


sub new {
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->{ECHOES} = {};
   $self->Commands(
      'echo' => \&NewEcho,
      'key' => \&Key,
   );
   $self->Setup;

   return $self;
}

sub Echo {
   my $self = shift;
   my $key = shift;
   if (@_) { $self->{ECHOES}->{$key} = shift; }
   return $self->{ECHOES}->{$key};
}

sub EchoExists {
   my ($self, $key) = @_;
   return exists $self->{ECHOES}->{$key}
}


sub DefaultTable {
   my $self = shift;
   return [
        3 => 'copy',
        8 => \&DecodeBS,            #Backspace
        9 => \&DecodeTab,           #Tab
       13 => \&DecodeEnter,         #Enter or Ctrl-m, Ctrl-m does not produce a newline through the native handler. this might confuse plugins.
       22 => \&DecodePaste,         #Ctrl-v
       24 => \&DecodeCut,           #Ctrl-x
      127 => \&DecodeDel,           #Delete
      322 => 'insertkey',           #Insertkey pressed
   ]
}

sub DecodeBS {
   my $self = shift;
   unless ($self->Broadcast('backspace')) {
      my $tc = $self->TxtCtrl;
      if (($tc->GetInsertionPoint > 0) and $tc->IsEditable) {
         my ($selb, $sele) = $tc->GetSelection;
         if ($selb eq $sele) { #no selection
            my $p = $tc->GetInsertionPoint;
            if ($p > 0) {
               #broadcast remove: no selection => UndoRedo does it's own magic. Highlighter still needs to pick up on it.
               return $self->Broadcast('remove', $p - 1, $tc->GetRange($p -1, $p), 0, $p);
            }
         } else { #selection
            # broadcast uremove: there is a selection => UndoRedo records this straight into the undo stack.
            return $self->Broadcast('remove', $selb, $tc->GetStringSelection, 1, $tc->GetInsertionPoint);
         }
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0
}

sub DecodeCut {
   my $self = shift;
   unless ($self->Broadcast('cut')) {
      my $tc = $self->TxtCtrl;
      if ($tc->IsEditable) {
         my ($selb, $sele) = $tc->GetSelection;
         if ($selb ne $sele) { #there is a selection
            return $self->Broadcast('remove', $selb, $tc->GetStringSelection, 1, $tc->GetInsertionPoint);
         }
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0
}

sub DecodeDel {
   my $self = shift;
   unless ($self->Broadcast('delete')) {
      my $tc = $self->TxtCtrl;
      if (($tc->GetInsertionPoint < $tc->GetLastPosition) and $tc->IsEditable) {
         my ($selb, $sele) = $tc->GetSelection;
         if ($selb eq $sele) { #no selection
            my $p = $tc->GetInsertionPoint;
            if ($p < $tc->GetLastPosition) {
               return $self->Broadcast('remove', $p, $tc->GetRange($p, $p + 1), 0, $p);
            }
         } else {
            return $self->Broadcast('remove', $selb, $tc->GetStringSelection, 1, $tc->GetInsertionPoint);
         }
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0
}

sub DecodeEnter {
   my $self = shift;
   unless ($self->Broadcast('enter')) {
      my $tc = $self->TxtCtrl;
      if ($tc->IsMultiLine and $tc->IsEditable) {
         return $self->KeyWriteable(13)
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0
}

sub DecodePaste {
   my $self = shift;
   unless ($self->Broadcast('paste')) {
      my $tc = $self->TxtCtrl;
      if ($tc->IsEditable) {
         my ($selb, $sele) = $tc->GetSelection;
         my $ins = $tc->GetInsertionPoint;
         if ($selb eq $sele) { #there is no selection
            return $self->Broadcast('write', $ins, $tc->GetClipboardText, 0);
         } else {
            return $self->Broadcast('replace', $selb, $tc->GetStringSelection, $tc->GetClipboardText, 1);
         }
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0;
}

sub DecodeTab {
   my $self = shift;
   unless ($self->Broadcast('tab')) {
      my $tc = $self->TxtCtrl;
      if ($tc->IsEditable) {
         return $self->KeyWriteable(9)
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0
}

sub Key {
   my ($self, $event) = @_;
   my $k = $event->GetKeyCode;
   my $tc = $self->TxtCtrl;
   if ($debug) {
      my $r = $event->GetRawKeyCode;
#       print "captured key: $k, raw: $r\n";
   }
   if ($tc->IsWriteable($k)) { #writeable character
      return $self->KeyWriteable($k);
   } elsif ($self->EchoExists($k)) {
      my $echo = $self->Echo($k);
      if (ref $echo) {
         return &$echo($self, $event)
      } else {
         if ($debug) { print "broadcasting $echo\n" }
         return $self->Broadcast($echo);
      }
   } 
   return 0;
}

sub KeyWriteable {
   my ($self, $key) = @_;
   unless ($self->Broadcast('writeable')) {
      my $tc = $self->TxtCtrl;
      if ($tc->IsEditable) {
         if ($tc->HasSelection) {
            my ($selb, $sele) = $tc->GetSelection;
            return $self->Broadcast('replace', $selb, $tc->GetStringSelection, chr($key), 1);
         } else {
            my $pos = $self->TxtCtrl->GetInsertionPoint;
            return $self->Broadcast('write', $pos, chr($key), 0);
         }
      } else {
         return $self->Broadcast('cancel')
      }
   }
   return 0;
}

sub NewEcho {
   my $self = shift;
   $self->Echo(@_);
   return 1
}

sub Setup {
   my ($self, $tb, $clr) = @_;
   unless (defined($tb)) {
      $tb = $self->DefaultTable;
   }
   if (defined($clr) and $clr) {
      $self->{ECHOS} = {};
   }
   my @table = @$tb;
   while (@table) {
      my $key = shift @table;
      my $echo = shift @table;
      $self->Echo($key, $echo);
   }
}


1;
__END__
