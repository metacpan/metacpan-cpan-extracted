#
#   Copyright (c) 2004-2016 Lincoln A. Baxter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file,

package Sys::SigAction;
require 5.005;
use strict;
use warnings;
use POSIX qw( :signal_h ceil INT_MAX ) ;
require Exporter;
use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );

#support high resolution time transparently in timeout_call by defining
#the function sig_alarm() which calls Time::HiRes::alarm if available
#or core alarm with the ceil of the value passed otherwise.
#timeout_call uses sig_alarm()

#replacement for alarm, factional second arg in floating point format:
use Sys::SigAction::Alarm qw( ssa_alarm );
sub sig_alarm 
{
   my $secs = shift;
   ssa_alarm( $secs );
}

#use Data::Dumper;

@ISA = qw( Exporter );
@EXPORT_OK = qw( set_sig_handler timeout_call sig_name sig_number sig_alarm );
$VERSION = '0.23';

use Config;
my %signame = ();
my %signo = ();
{
   defined $Config{sig_name} or die "This OS does not support signals?";
   my $i = 0;     # Config prepends fake 0 signal called "ZERO".
   my @numbers = split( ' ' ,$Config{sig_num} );
   foreach my $name (split(' ', $Config{sig_name})) 
   {
      $signo{$name} = $numbers[$i];
      $signame{$signo{$name}} = $name;
      #print "name=$name num=" .$numbers[$i] ."\n" ;
      $i++;
   }
}

sub sig_name {
   my ($sig) = @_;
   return $sig if $sig !~ m/^\d+$/ ;
   return $signame{$sig} ;
}
sub sig_number {
   my ($sig) = @_;
   return $sig if $sig =~ m/^\d+$/;
   return $signo{$sig} ;
}
#if ( $] < 5008 ) {
#   #over write definitions of sig_name and sig_number
#   sub sig_name { warn "sig_name() not supported on perl versions < 5.8.0"; }
#   sub sig_number { warn "sig_number() not supported on perl versions < 5.8.0"; }
#}

my $use_sigaction = ( $] >= 5.008 and $Config{d_sigaction} );

sub _attrs_warning($)
{
   my ( $attrs ) =  @_ ;
   #my $act =  POSIX::SigAction->new( $handler ,$mask ,$attrs->{flags} ,$attrs->{safe} );
   #steve ( SPURKIS@cpan.org submitted  http://rt.cpan.org/Ticket/Display.html?id=19916 
   #  puts out the above line is a mis-interpretation of the API for POSIX::SigAcation
   #  so here is the fix (per his suggestion)... lab:
   #
   #http://rt.cpan.org/Public/Bug/Display.html?id=21777
   #2006-09-29: in perl 5.8.0 (RH) $act->safe() is broken 
   #            safe is not available until 5.8.2
   #            DAMN... it was in my docs too... 
   if ( exists( $attrs->{safe} ) )
   {
      if ( ( $] < 5.008002 ) && defined($attrs->{safe}) && $attrs->{safe} ) 
      {
         warn "safe mode is not supported in perl versions less than 5.8.2";
         delete $attrs->{safe};
      }
   }

}
sub set_sig_handler( $$;$$ )
{
   my ( $sig ,$handler ,$attrs ) = @_;      
   $attrs = {} if not defined $attrs;
   _attrs_warning($attrs);
   if ( not $use_sigaction )
   {
      #warn '$flags not supported in perl versions < 5.8' if $] < 5.008 and defined $flags;
      $sig = sig_name( $sig );
      my $ohandler = $SIG{$sig};
      $SIG{$sig} = $handler;
      return if not defined wantarray;
      return Sys::SigAction->new( $sig ,$ohandler );
   }
   my $act = mk_sig_action( $handler ,$attrs );
   return set_sigaction( sig_number($sig) ,$act );
}
sub mk_sig_action($$)
{
   my ( $handler ,$attrs ) = @_;      
   die 'mk_sig_action requires perl 5.8.0 or later' if $] < 5.008;
   $attrs->{flags} = 0 if not defined $attrs->{flags};
   $attrs->{mask} = [] if not defined $attrs->{mask};
   #die '$sig is not defined' if not defined $sig;
   #$sig = sig_number( $sig );
   my @siglist = ();
   foreach (@{$attrs->{mask}}) { push( @siglist ,sig_number($_)); };
   my $mask = POSIX::SigSet->new( @siglist );

   my $act =  POSIX::SigAction->new( $handler ,$mask ,$attrs->{flags} ); 

   #apply patch suggested by CPAN bugs
   #  http://rt.cpan.org/Ticket/Display.html?id=39599
   #  http://rt.cpan.org/Ticket/Display.html?id=39946 (these are dups)
   #using safe mode with masking signals still breaks the masking of signals!
   $act->safe($attrs->{safe}) if defined $attrs->{safe};
   return $act;
}


sub set_sigaction($$)
{ 
   my ( $sig ,$action  ) = @_;
   die 'set_sigaction() requires perl 5.8.0 or later' if $] < 5.008;
   die '$sig is not defined' if not defined $sig;
   die '$action is not a POSIX::SigAction' if not UNIVERSAL::isa( $action ,'POSIX::SigAction' );
   $sig = sig_number( $sig );
   if ( defined wantarray )
   {
      my $oact = POSIX::SigAction->new();
      sigaction( $sig ,$action ,$oact );
      return Sys::SigAction->new( $sig ,$oact );
   }
   else
   {
      sigaction( $sig ,$action );
   }
}

use constant TIMEDOUT => {};
sub timeout_call( $$@ )
{
   my ( $timeout, $code, @args ) = @_;

   if (!$timeout) {
      &$code(@args);
      return 0;
   }

   my $timed_out = 0;
   eval {
      my $sa = set_sig_handler( SIGALRM ,sub { $timed_out = 1; die TIMEDOUT; } );
      eval {
         sig_alarm( $timeout );
         &$code(@args); 
      };
      sig_alarm(0);
      die $@ if $@;
   };
   die $@ if $@ and (not ref $@ or $@ != TIMEDOUT);

   return $timed_out;
}
sub new {
   my ($class,$sig,$act) = @_;
   bless { SIG=>$sig ,ACT => $act } ,$class ;
}
sub DESTROY 
{
   if ( $use_sigaction )
   {
      set_sigaction( $_[0]->{'SIG'} ,$_[0]->{'ACT'} );
   }
   else
   {
      #set it to default if not defined (suppress undefined warning)
      $SIG{$_[0]->{'SIG'}} = defined $_[0]->{'ACT'} ? $_[0]->{'ACT'} : 'DEFAULT' ;
   }
   return;
}

1;

__END__

=head1 NAME

Sys::SigAction - Perl extension for Consistent Signal Handling

=head1 SYNOPSYS

   #do something non-interrupt able
   use Sys::SigAction qw( set_sig_handler );
   {
      my $h = set_sig_handler( 'INT' ,'mysubname' ,{ flags => SA_RESTART } );
      ... do stuff non-interrupt able
   } #signal handler is reset when $h goes out of scope

or

   #timeout a system call:
   use Sys::SigAction qw( set_sig_handler );
   eval {
      my $h = set_sig_handler( 'ALRM' ,\&mysubname ,{ mask=>[ 'ALRM' ] ,safe=>1 } );
      eval {
         alarm(2)
         ... do something you want to timeout
         alarm(0);
      };
      alarm(0); 
      die $@ if $@;
   }; #signal handler is reset when $h goes out of scope
   if ( $@ ) ...

or

   use Sys::SigAction;
   my $alarm = 0;
   eval {
      my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { $alarm = 1; } );
      eval {
         alarm(2)
         ... do something you want to timeout
         alarm(0);
      };
      alarm(0); 
      die $@ if $@;
   }; #signal handler is reset when $h goes out of scope
   if ( $@ or $alarm ) ...

or

   use Sys::SigAction;
   my $alarm = 0;
   Sys::SigAction::set_sig_handler( 'TERM' ,sub { "DUMMY" } );
   #code from here on uses new handler.... (old handler is forgotten)

or

   use Sys::SigAction qw( timeout_call );
   if ( timeout_call( 5 ,sub { $retval = DoSomething( @args ); } )
   {
      print "DoSomething() timed out\n" ;
   }

or

   #use a floating point (fractional seconds) in timeout_call
   use Sys::SigAction qw( timeout_call );
   if ( timeout_call( 0.1 ,sub { $retval = DoSomething( @args ); } )
   {
      print "DoSomething() timed out\n" ;
   }

=head1 ABSTRACT

This module implements C<set_sig_handler()>, which sets up a signal
handler and (optionally) returns an object which causes the signal
handler to be reset to the previous value, when it goes out of scope.

Also implemented is C<timeout_call()> which takes a timeout value, a
code reference and optional arguments, and executes the code reference
wrapped with an alarm timeout. timeout_call accepts seconds in floating
point format, so you can time out call with a resolution of 0.000001
seconds. If C<Time::HiRes> is not loadable or C<Time::HiRes::ualarm()> does
not work, then the factional part of the time value passed to C<timeout_call()>
will be raise to the next higher integer with POSIX::ceil(). This means
that the shortest a timeout can be in 1 second.
 

Finally, two convenience routines are defined which allow one to get the
signal name from the number -- C<sig_name()>, and get the signal number
from the name -- C<sig_number()>.

=head1 DESCRIPTION

Prior to version 5.8.0 perl implemented 'unsafe' signal handling.
The reason it is consider unsafe, is that there is a risk that a
signal will arrive, and be handled while perl is changing internal
data structures.  This can result in all kinds of subtle and not so
subtle problems.  For this reason it has always been recommended that
one do as little as possible in a signal handler, and only variables
that already exist be manipulated.

Perl 5.8.0 and later versions implements 'safe' signal handling
on platforms which support the POSIX sigaction() function.  This is
accomplished by having perl note that a signal has arrived, but deferring
the execution of the signal handler until such time as it is safe to do
so.  Unfortunately these changes can break some existing scripts, if they
depended on a system routine being interrupted by the signal's arrival.
The perl 5.8.0 implementation was modified further in version 5.8.2.

From the perl 5.8.2 B<perlvar> man page:

   The default delivery policy of signals changed in Perl 5.8.0 
   from immediate (also known as "unsafe") to deferred, also 
   known as "safe signals".  


The implementation of this changed the C<sa_flags> with which
the signal handler is installed by perl, and it causes some
system routines (like connect()) to return EINTR, instead of another error
when the signal arrives.  The problem comes when the code that made 
the system call sees the EINTR code and decides it's going to call it 
again before returning. Perl doesn't do this but some libraries do, including for
instance, the Oracle OCI library.

Thus the 'deferred signal' approach (as implemented by default in
perl 5.8 and later) results in some system calls being
retried prior to the signal handler being called by perl. 
This breaks timeout logic for DBD-Oracle which works with
earlier versions of perl.  This can be particularly vexing, when, for instance,
the host on which a database resides is not available:  C<DBI-E<gt>connect()>
hangs for minutes before returning an error (and cannot even be interrupted
with control-C, even when the intended timeout is only seconds). 
This is because SIGINT appears to be deferred as well.  The
result is that it is impossible to implement open timeouts with code
that looks like this in perl 5.8.0 and later:

   eval {
      eval {
         local $SIG{ALRM} = sub { die "timeout" };
         alarm 2;
         $sth = DBI->connect(...);
         alarm 0;
      };
      alarm 0;
      die if $@;
   };

Or as the author of bug #50628 pointed out, 
might probably better be written as:

   eval {
      local $SIG{ALRM} = sub { die "timeout" };
      eval {
         alarm 2;
         $sth = DBI->connect(...);
         alarm 0;
      };
      alarm 0;
      die if $@;
   };


The solution, if your system has the POSIX sigaction() function,
is to use perl's C<POSIX::sigaction()> to install the signal handler.
With C<sigaction()>, one gets control over both the signal mask, and the
C<sa_flags> that are used to install the handler.  Further, with perl
5.8.2 and later, a 'safe' switch is provided which can be used to ask
for safe(r) signal handling. 
   
Using sigaction() ensures that the system call won't be
resumed after it's interrupted, so long as die is called
within the signal handler.  This is no longer the case when 
one uses C<$SIG{name}> to set signal
handlers in perls >= 5.8.0.

The usage of sigaction() is not well documented however, and in perl
versions less than 5.8.0, it does not work at all. (But that's OK, because
just setting C<$SIG> does work in that case.)  Using sigaction() requires
approximately 4 or 5 lines of code where previously one only had to set
a code reference into the %SIG hash.

Unfortunately, at least with perl 5.8.0, the result is that doing this
effectively reverts to the 'unsafe' signals behavior.  It is not clear
whether this would be the case in perl 5.8.2, since the safe flag can be used
to ask for safe signal handling.  I suspect this separates the logic
which uses the C<sa_flags> to install the handler, and whether deferred
signal handling is used.

The reader should also note, that the behavior of the 'safe' 
attribute is not consistent with what this author expected. 
Specifically, it appears to disable signal masking. This can be
examined further in the t/safe.t and the t/mask.t regression tests.
Never-the-less, Sys::SigAction provides an easy mechanism for
the user to recover the pre-5.8.0 behavior for signal handling, and the
mask attribute clearly works. (see t/mask.t) If one is looking for
specific safe signal handling behavior that is considered broken,
and the breakage can be demonstrated, then a patch to t/safe.t would be 
most welcome.

This module wraps up the POSIX:: routines and objects necessary to call
sigaction() in a way that is as efficient from a coding perspective as just
setting a localized C<$SIG{SIGNAL}> with a code reference.  Further, the
user has control over the C<sa_flags> passed to sigaction().  By default,
if no additional args are passed to sigaction(), then the signal handler
will be called when a signal (such as SIGALRM) is delivered.

Since sigaction() is not fully functional in perl versions less than
5.8, this module implements equivalent behavior using the standard
C<%SIG> array.  The version checking and implementation of the 'right'
code is handled by this module, so the user does not have to write perl
version dependent code.  The attrs hashref argument to set_sig_handler()
is silently ignored, in perl versions less than 5.8.  When this module 
was developed it was tested on perl 5.005 on solaris.  That was in 2004.
Now only perl versions >= 5.6 are supported. If you want this to work on 
perl 5.5 you will have comment out "use warnings" everywhere.

It is hoped that with the use of this module, your signal handling
behavior can be coded in a way that does not change from one perl version
to the next, and that sigaction() will be easier for you to use.

=head1 Note on "Double evals"

CPAN bug #50628 which was filed against Sys::SigAction-0.11
noting that the sample code was "buggy" because the evals 
that wrapped the code we wanted to timeout
might die for an unanticipated reason, before the alarm could be cleared.
In that case, as the bug writer noted, if the alarm expires before the final alarm(0)
can be called, either the code will completely die because
there is no SIGALRM handler in place to catch the signal, or the
wrong handler (not the local handler) will be called. 

All the code samples in this module have been modified to account for this.  
Additionally we have made the same change in timeout_call() which could
have exhibited this behavior, though the AUTHOR never knowing experienced it.

=head1 FUNCTIONS

=head2  set_sig_handler() 

   $sig ,$handler ,$attrs 
   

Install a new signal handler and (if not called in a void context)
returning a Sys::SigAction object containing the old signal handler,
which will be restored on object destruction.

   $sig     is a signal name (without the 'SIG') or number.

   $handler is either the name (string) of a signal handler
            function or a subroutine CODE reference. 

   $attrs   if defined is a hash reference containing the 
            following keys:

            flags => the flags the passed sigaction

               ex: SA_RESTART (defined in your signal.h)

            mask  => the array reference: signals you
                     do not want delivered while the signal
                     handler is executing

               ex: [ SIGINT SIGUSR1 ] or
               ex: [ qw( INT USR1 ]

            safe  => A boolean value requesting 'safe' signal
                     handling (only in 5.8.2 and greater)
                     earlier versions will issue a warning if
                     you use this  

                     NOTE: This breaks the signal masking

=head2 timeout_call()

   $timeout, $coderef, @args

Given a code reference, and a timeout value (in seconds), timeout_call()
will (in an eval) setup a signal handler for SIGALRM (which will die),
set an alarm clock, and execute the code reference with optional
arguments @args. $timeout (seconds) may be expressed as a floating point
number. 


If Time::HiRes is present and useable, timeout_call() can be used with a
timer resolution of 0.000001 seconds. If HiRes is not loadable, 
Sys::SigAction will "do the right thing" and convert the factional 
seconds to the next higher integer value using the posix ceil() function.


If the alarm goes off the code will be interrupted.  The alarm is
canceled if the code returns before the alarm is fired.  The routine
returns true if the code being executed timed out. (was interrupted).
Exceptions thrown by the code executed are propagated out.

The original signal handler is restored, prior to returning to the caller.

=head2 sig_alarm()

ex:

   sig_alarm( 1.2 ); 

sig_alarm() is a drop in replacement for the standard alarm() function.
The argument may be expressed as a floating point number. 

If Time::HiRes is present and useable, the alarm timers will be set
to the floating point value with a resolution of 0.000001 seconds.  
If Time::HiRes is not available then the a fractional value in the argument will 
be raised to the next higher integer value. 

=head2 sig_name()

Return the signal name (string) from a signal number.

ex:

   sig_name( SIGINT ) returns 'INT'
   

=head2 sig_number()

Return the signal number (integer) from a signal name (minus the SIG part).

ex:

   sig_number( 'INT' ) returns the integer value of SIGINT;


=head1 MULTITHREADED PERL


Sys::SigAction works just fine on perls built with multithread support in 
single threaded perl applications. However, please note that
using Signals in a multi-thread perl application is unsupported.

Read the following from perldoc perlthrtut:

   ... mixing signals and threads may be problematic.
   Implementations are platform-dependent, and even the POSIX semantics
   may not be what you expect (and Perl doesn't even give you the full
   POSIX API).  For example, there is no way to guarantee that a signal
   sent to a multi-threaded Perl application will get intercepted by
   any particular thread.

That said, perl documentation for perl threading discusses a a way of
emulating signals in multi-threaded applications, when safe signals
is in effect. See perldoc threads and search for THREAD SIGNALLING.
I have no test of multithreading and this module.  If you think they
could be used compatibly and would provide value, patches are welcome.

=head1 AUTHOR

   Lincoln A. Baxter <lab-at-lincolnbaxter-dot-com>

=head1 COPYRIGHT

   Copyright (c) 2004-2016 Lincoln A. Baxter
   All rights reserved.

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file,


=head1 SEE ALSO

   perldoc perlvar 
   perldoc POSIX


