package P9Y::ProcessTable::Role::Process::OS::MSWin32;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.08'; # VERSION

#############################################################################
# Modules

# use sanity;
use strict qw(subs vars);
no strict 'refs';
use warnings FATAL => 'all';
no warnings qw(uninitialized);

use Moo::Role;

### FIXME: Can't get Win32::API to not crash on me... ###

use Win32::Process;
#use Win32::API;
#use Win32::API::Callback;

BEGIN {
   #Win32::API->Import( 'user32', 'EnumWindows',              'KN', 'N' );
   #Win32::API->Import( 'user32', 'GetWindowThreadProcessId', 'NP', 'N' );
   #Win32::API->Import( 'user32', 'PostMessage',              'NINN', 'N' );
}

no warnings 'uninitialized';

my $pi = Win32::Process::Info->new();

my $IS_CYGWIN = ($^O =~ /cygwin/i) ? 1 : 0;

#############################################################################
# Methods

sub _win32_proc {
   my $self = shift;
   my $obj;
   Win32::Process::Open($obj, $self->pid, 0);
   return $obj;
}

sub kill {
   my ($self, $sig) = @_;

   # Windows's signal.h actually has plenty of gaps, but it still follows Linux's model where
   # there isn't gaps.  Thus, we'll just fill in the blanks.

   # POSIX = 0 HUP INT QUIT ILL TRAP ABRT . FPE KILL . SEGV . PIPE ALRM TERM . . . . . . ABRT
   # 0x0010 = WM_CLOSE
   my $posix2wm = [
      0, 0x0010, 0x0010, qw/kill kill kill kill . kill kill . kill ./, 0x0010, 0x0010, 0x0010, qw/. . . . . . kill/
   ];

   $sig = $posix2wm->[$sig];
   return if (!$sig || $sig eq '.');
   if    ($sig eq '0') {
      return CORE::kill($sig, $self->pid);
   }
   elsif ($sig eq 'kill') {
      return $self->_win32_proc->Kill(255);
   }
   else {
      #my $cb = Win32::API::Callback->new( sub {
      #   my $hwnd = shift;
      #   my $pid = 0;
      #
      #   #GetWindowThreadProcessId($hwnd, \$pid);
      #   print "foo\n";
      #   #PostMessage($hwnd, $sig) if ($$pid && $$pid == $self->pid);
      #}, "NN", "N" );
      #
      #my $ret = EnumWindows($cb, 0);
      return $self->_win32_proc->Kill(255);
   }
}

around priority => sub {
   my ($orig, $self, $pri) = @_;
   return $orig->($self) if @_ == 2;

   $self->_win32_proc->SetPriorityClass($pri);
   $self->_set_priority($pri);
};

42;
