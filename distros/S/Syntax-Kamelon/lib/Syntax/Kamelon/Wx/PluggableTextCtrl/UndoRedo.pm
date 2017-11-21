package Syntax::Kamelon::Wx::PluggableTextCtrl::UndoRedo;


use strict;
use warnings;
use Carp;

use base qw( Syntax::Kamelon::Wx::PluggableTextCtrl::BasePlugin );
use Wx::Event qw( EVT_CHAR );

my $debug = 0;

if ($debug) {
   use Data::Dumper;
}

sub new {
   my $class = shift;
   my $self = $class->SUPER::new(@_);

   $self->{BUFFER} = "";
   $self->{BUFFERMODE} = '';
   $self->{BUFFERNEXTCALL} = 0;
   $self->{BUFSTART} = 0;
   $self->{FLUSHKEYS} = [9, 13, 32];
   $self->{LASTCALL} = "";
   $self->{REPLACEBUFFER} = "";
   $self->{REDOSTACK} = [];
   $self->{UNDOSTACK} = [];
   my $tc = $self->TxtCtrl;
   $self->Require('KeyEchoes');
   $tc->Listening(1);
   unless($self->Broadcast('echo', 25, 'redo')) { carp "could not assign Ctrl-y to redo\n" }
   unless($self->Broadcast('echo', 26, 'undo')) { carp "could not assign Ctrl-z to undo\n" }
   $self->Commands(
      'backspace' => \&BufferModeBs,
      'cancel' => \&CancelCall,
      'canundo' => \&CanUndo,
      'canredo' => \&CanRedo,
      'clear' =>\&Clear,
      'delete' => \&BufferModeDel,
      'replace' => \&RecordReplace,
      'redo' => \&Redo,
      'undo' => \&Undo,
      'remove' => \&RecordRemove,
      'write' => \&RecordWrite,
      'writeable' => \&BufferModeWr,
   );
   if ($debug) { print "dumping commands "; print Dumper $self->{COMMANDS} }

   return $self;
}

sub Buffer {
   my $self = shift;
   if (@_) { $self->{BUFFER} = shift; }
   return $self->{BUFFER};
}

sub BufferCall { #just invented a new verb here: to buffer, store this call in the character buffer.

   my $self = shift; 
   
   if ($self->BufferNextCall) {
      if ($debug) { print "BufferCall called\n"; }
      my $call = shift; my $index = shift; my $char = shift;
      my $otxt = undef;
      if ($call eq 'replace') { $otxt = shift }
      my $sel = shift; my $pos = shift;

      unless ($sel or (length($char) ne 1)) {
         my $mode = $self->BufferMode;

         if ($mode eq 'backspace') {
            if ($call eq 'remove') {
               if ($debug) { print "performing backspace: '$char'\n" }
               $self->BufferNextCall(0);
               my $buf = $self->Buffer;
               $self->Buffer($char . $buf);
               $self->BufStart($index);
               $self->LastCall($call);
               return 1
            } else {
               carp "unexpected call '$call', it should have been 'remove'\n";
            }
         } elsif ($mode eq 'delete') {
            if ($call eq 'remove') {
               if ($debug) { print "performing delete: '$char'\n" }
               $self->BufferNextCall(0);
               my $buf = $self->Buffer;
               $self->Buffer($buf . $char);
               $self->BufStart($index);
               $self->LastCall($call);
               return 1
            } else {
               carp "unexpected call '$call', it should have been 'remove'\n";
            }

         } elsif ($mode eq 'writeable') {
            if (($call eq 'write') or ($call eq 'replace')) {
               if ($debug) { print "performing writeable: '$char'\n" }
               $self->BufferNextCall(0);
               if ($self->IsFlushKey(ord($char))) {
                  my $buf = $self->Buffer;
                  my $len = length($buf);
                  unless (($buf eq '') or ($self->IsFlushKey(ord(substr($buf, $len - 1))))) {
                     $self->Flush;
                  }
               }
               if ($call ne $self->LastCall) {
                  $self->Flush;
               }
               $self->LastCall($call);
               unless ($self->Buffer) { $self->BufStart($index); }
               $self->Buffer($self->Buffer . $char);
               if ($call eq 'overwrite') {
                  $self->ReplaceBuffer($self->ReplaceBuffer . $otxt);
               }
               return 1
            } else {
               carp "unexpected call '$call', it should have been 'write' or 'replace'\n";
            }
         }
      }
   }
   return 0
}

sub BufferMode {
   my $self = shift;
   if (@_) { $self->{BUFFERMODE} = shift; }
   return $self->{BUFFERMODE};
}

sub BufferModeBs {
   my $self = shift;
   return $self->BufferModeSwitch('backspace')
}

sub BufferModeDel {
   my $self = shift;
   return $self->BufferModeSwitch('delete')
}

sub BufferModeSwitch {
   my ($self, $call) = @_;
   $self->BufferNextCall(1);
   my $mode = $self->BufferMode;
   if ($mode ne $call) {
      if ($debug) { print "Switching to buffer mode '$call'\n"; }
      $self->Flush;
      $self->BufferMode($call);
   }
   return 0
}

sub BufferModeWr {
   my $self = shift;
   return $self->BufferModeSwitch('writeable')
}

sub BufferNextCall {
   my $self = shift;
   if (@_) { $self->{BUFFERNEXTCALL} = shift; }
   return $self->{BUFFERNEXTCALL};
}

sub BufStart {
   my $self = shift;
   if (@_) { $self->{BUFSTART} = shift; }
   return $self->{BUFSTART};
}

sub CancelCall {
   my $self = shift;
   $self->BufferNextCall(0);
   if ($debug) { print "received cancel \n"; }
   return 0;
}

sub CanUndo {
   my $self = shift;
   my $stack = $self->{UNDOSTACK};
   my $size = @$stack;
   return ($size > 0)
}

sub CanRedo {
   my $self = shift;
   my $stack = $self->{REDOSTACK};
   my $size = @$stack;
   return ($size > 0)
}

sub Clear {
   my $self = shift;
   $self->ResetRedo;
   $self->ResetUndo;
   $self->BufStart(0);
   $self->Buffer('');
   $self->BufferMode('');
   $self->ReplaceBuffer('');
   $self->LastCall('');
   return 0;
}

sub Flush {
   my $self = shift;
   my $buf = $self->Buffer;
   $self->Buffer('');
   my $bnc = $self->BufferNextCall;
   $self->BufferNextCall(0);
   my $pos = $self->BufStart;
   if ($buf ne '') {
      my $mode = $self->BufferMode;
      if ($mode eq 'delete') {
         $self->RecordUndo('remove', $pos, $buf, 0, $pos);
      } elsif ($mode eq 'backspace') {
         $self->RecordUndo('remove', $pos, $buf, 0);
      } elsif ($mode eq 'writeable') {
         my @call = ();
         my $ovr = $self->ReplaceBuffer;
         if ($ovr eq '') { push @call, 'write' } else { push @call, 'replace' }
         push @call, $pos, $buf;
         if ($ovr ne '') { push @call, $ovr }
         push @call, 0;
         if ($debug) { print "Flushing: @call'\n"; }
         $self->RecordUndo(@call);
      } else {
         carp "invalid buffer mode $mode\n";
      }
   }
   $self->BufferNextCall($bnc);
}

sub FlushKeys {
   my $self = shift;
   if (@_) { $self->{FLUSHKEYS} = shift; }
   return $self->{FLUSHKEYS};
}


sub IsFlushKey {
   my ($self, $key) = @_;
   my $fk = $self->FlushKeys;
   foreach (@$fk) {
      if ($key eq $_) {
         return 1
      }
   }
   return 0
}

sub LastCall {
   my $self = shift;
   if (@_) { $self->{LASTCALL} = shift; }
   return $self->{LASTCALL};
}

sub ReplaceBuffer {
   my $self = shift;
   if (@_) { $self->{REPLACEBUFFER} = shift; }
   return $self->{REPLACEBUFFER};
}

sub PullUndo {
   my $self = shift;
   my $stack = $self->{UNDOSTACK};
#   if ($debug) { print "undostack: ", Dumper $self->{UNDOSTACK} }
   return pop(@$stack);
}

sub PullRedo {
   my $self = shift;
   my $stack = $self->{REDOSTACK};
   return pop(@$stack);
}

sub PushUndo {
   my $self = shift;
   my $stack = $self->{UNDOSTACK};
   push(@$stack, @_);
#   if ($debug) { print "undostack: ", Dumper $self->{UNDOSTACK} }
}

sub PushRedo {
   my $self = shift;
   my $stack = $self->{REDOSTACK};
   push(@$stack, @_);
#   if ($debug) { print "redostack: ", Dumper $self->{UNDOSTACK} }
}

sub RecordReplace {
   my $self = shift;
   return $self->RecordUndo('replace', @_);
}

sub RecordRemove {
   my $self = shift;
   return $self->RecordUndo('remove', @_);
}

sub RecordUndo {
   my $self = shift;
   unless ($self->BufferCall(@_)) {
      $self->Flush;
      $self->ResetRedo;
      $self->PushUndo([@_]);
   }
   return 0;
}

sub RecordWrite {
   my $self = shift;
   return $self->RecordUndo('write', @_);
}

sub Redo {
   my $self = shift;
   $self->CancelCall;
   $self->Flush;
   if ($self->CanRedo) {
      my $o = $self->PullRedo;
      $self->PushUndo($o);
      my @call = @$o;
      my $mode = shift @call;
      if ($mode eq 'write') {
         return $self->Broadcast('dowrite', @call);
      } elsif ($mode eq 'remove') {
         return $self->Broadcast('doremove', @call);
      } elsif ($mode eq 'replace') {
         return $self->Broadcast('doreplace', @call)
      } else {
         carp "invalid redo mode $mode\n";
      }
   }
   return 0;
}

sub ResetRedo {
   my $self = shift;
   $self->{REDOSTACK} = [];
}

sub ResetUndo {
   my $self = shift;
   $self->{UNDOSTACK} = [];
}

sub Undo {
   my $self = shift;
   $self->CancelCall;
   $self->Flush;
   if ($self->CanUndo) {
      my $o = $self->PullUndo;
      $self->PushRedo($o);
      my @call = @$o;
      my $mode = shift @call;
      if ($mode eq 'write') {
         return $self->Broadcast('doremove', @call);
      } elsif ($mode eq 'remove') {
         return $self->Broadcast('dowrite', @call);
      } elsif ($mode eq 'replace') {
         my ($index, $old, $new, $sel, $ins) = @call;
         if ($self->Broadcast('doremove', $index, $new, 0)) {
            return $self->Broadcast('dowrite', $index, $old, $ins)
         }
      } else {
         carp "invalid undo mode $mode\n";
      }
   }
   return 0
}


1;
__END__
