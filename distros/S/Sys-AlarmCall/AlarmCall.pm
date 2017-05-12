package Sys::AlarmCall;
require Exporter;
use Carp qw(croak);
@ISA = qw(Exporter);
@EXPORT = qw(alarm_call);

use vars qw($SCALAR_ERROR $ARRAY_ERROR $TIMEOUT);

use strict;

# Documentation in pod format after __END__ token. See Perl
# man pages to convert pod format to man, html and other formats.

$Sys::AlarmCall::VERSION = 1.2;

my @ARG_STRINGS = (
'$_[0]',
'$_[0],$_[1]',
'$_[0],$_[1],$_[2]',
'$_[0],$_[1],$_[2],$_[3]',
'$_[0],$_[1],$_[2],$_[3],$_[4]',
'$_[0],$_[1],$_[2],$_[3],$_[4],$_[5]'
);

$SCALAR_ERROR = 'ERROR ';
$ARRAY_ERROR = 'ERROR';
$TIMEOUT = 'TIMEOUT';

sub _alarm_sig_handler {
    die "Sys::AlarmCall::alarm_call went off\n";
}

sub alarm_call {
    # usage('INTEGER(>,0)','FUNCTION','LIST_OF_ARGUMENTS');
    my $timeout = shift;
    my $sub = shift;
    $timeout >= 1 || 
	croak("Sys::AlarmCall::alarm_call: Fatal error - timeout argument must be positive\n");
    my($old_handler,$old_alarm,$wantarray,$remaining_alarm);
    my($eval,$alarmed);

    $old_alarm = alarm(0);
    if ( $old_alarm && ($timeout > $old_alarm) ) {
	$timeout = $old_alarm;
    }

    $wantarray = wantarray;
    $old_handler = $SIG{'ALRM'};
    $SIG{'ALRM'} = "Sys::AlarmCall::_alarm_sig_handler";
    if (defined(ref($sub)) && (ref($sub) eq 'CODE') ) {
	unshift(@_,$sub);
	$sub = '&{shift(@_)}(@_);';
    } elsif ($sub =~ m/^->/) {
	unshift(@_,$sub);
        $sub = 'shift(@_)' . $sub . '(@_);';
    } elsif ($#_ < @ARG_STRINGS) {
	;#This is because many perl inbuilt functions won't compile
	;#if you just say func(@_) - they need to be given the
	;#proper number of arguments.
	$sub .= '(' . $ARG_STRINGS[$#_] . ')' ;
    } else {
	$sub .= '(@_)';
    }

    my ($callpack) = caller;
    $eval = 'alarm(' . $timeout . ");\npackage " . $callpack . ";\n" . $sub;
    my(@results,$results);
    if ($wantarray) {
	@results = eval $eval;
    } else {
	$results = eval $eval;
    }
    $remaining_alarm = alarm(0);
    $alarmed = ($@ eq "Sys::AlarmCall::alarm_call went off\n");
    if ($alarmed) {$remaining_alarm = 0}

    $SIG{'ALRM'} = $old_handler ? $old_handler : 'DEFAULT';

    if ( $old_alarm ) {;#There was a previous alarm pending
	$old_alarm = $old_alarm - $timeout + $remaining_alarm;
	if ($old_alarm > 0) {;#Reset it, excluding the elapsed time (at least)
	    alarm($old_alarm);
	} else {;#It should have gone off already - so set it off
	    kill 'ALRM',$$;
	}
    }

    ;#Three things to think about:
    ;#1. Did the eval fail due to some compile error or die call?
    ;#2. Did the eval get timed out?
    ;#3. Do we return an array or scalar?

    if ($alarmed) {return $wantarray ? ($TIMEOUT) : $TIMEOUT}
    elsif ($@) {return $wantarray ? ($ARRAY_ERROR,$@) : $SCALAR_ERROR . $@}
    $wantarray ? @results : $results;
}


1;
__END__
=head1 NAME

Sys::AlarmCall - A package to handle the logic in timing out calls
with alarm() and an ALRM handler, allowing nested calls as well.

=head1 SYNOPSIS

    use Sys::AlarmCall;

    $result = alarm_call($timeout1,$func1,@args1);
    @result = alarm_call($timeout2,$func2,@args2);

=head1 DESCRIPTION

Sys::AlarmCall provides a straightforward function call to use the alarm
handler. It also handles the logic which allows nested time out calls
if timeout calls are run thorugh the alarm_call() functions.

The main advantages of Sys::AlarmCall are that:

1. simple calls, e.g.

    @result = &func(@args); #Normal function call with '&'
    $result = func(@args);; #Normal function call
    @result = &$code_reference(@args);
    @result = $obj->func(@args); #Object method call

become simple calls:

    @result = alarm_call($timeout,'&func',@args);
    $result = alarm_call($timeout,'func',@args);
    @result = alarm_call($timeout,$code_reference,@args);
    @result = alarm_call($timeout,'->func',$obj,@args);

no need to futz around with alarms and handlers and
worrying about where to intercept the timer or set globals
or whatever; and

2. No need to worry if some subroutines within the
call also set a timeout - all that is handled logically
by the Sys::AlarmCall package (as long as the subroutines also
use the alarm_call function of course. But if they don't
you're up the same creek anyway).

Sys::AlarmCall exports one function,

=over 4

=item alarm_call TIMEOUT,FUNCTION,ARGS

Where TIMEOUT is a positive number (a fatal error occurs if TIMEOUT
is not at least one);

FUNCTION is a string giving the function name (and the '&' if wanted,
or preceded by '->', e.g. '->func', if using that, in which case the
calling object should be the first argument in ARGS);
and ARGS is the list of arguments to that function.

NOTE: As a side effect, normally fatal errors in the FUNCTION call are
caught and reported in the return.

In a scalar context, returns as follows:

If the FUNCTION produces any sort of error (including fatal 'die's which
are trapped), returns the error as a string, prepended by the value given
by the variable $Sys::AlarmCall::SCALAR_ERROR (default is 'ERROR ').

If the FUNCTION times out (i.e. doesn't return before TIMEOUT - 1),
returns the value given by the variable $Sys::AlarmCall::TIMEOUT (default
is 'TIMEOUT').

Otherwise, returns the scalar that the FUNCTION returns.

In an array context, returns as follows:

If the FUNCTION produces any sort of error (including fatal 'die's which
are trapped), returns a two element array, the first element being
the value given by the variable $Sys::AlarmCall::ARRAY_ERROR (default
is 'ERROR'), and the second element the error string produced.

If the FUNCTION times out (i.e. doesn't return before TIMEOUT - 1),
returns a one element array consisting of the value given by the
variable $Sys::AlarmCall::TIMEOUT (default is 'TIMEOUT').

Otherwise, returns the array that the FUNCTION returns.

Specific support for the -> construct has been added to alarm_call,
so that calling

    alarm_call($timeout,'->func',$obj,@args);

means that alarm_call will translate this to 

    $obj->func(@args);

Specific support for code references (e.g. $ref = sub {warn "this\n"})
has been added to alarm_call, so that calling

    alarm_call($timeout,$ref,@args);

means that alarm_call will translate this to

    &{$ref}(@args);

=back

Timers have resolutions of one second, but remember that a timeout
value of 15 will cause a timeout to occur at some point more than 14
seconds in the future. (see alarm() function in perl man page).
Also, nested calls decrease the resolution (make the uncertain interval
larger) by one second per nesting depth. This is because an alarm
call returns the time left rounded up to the next second.

=head1 EXAMPLES

EXAMPLE1

   use Sys::AlarmCall;
   alarm_call(3,'select',undef,undef,undef,10);

makes the select() system call which should just block for ten
seconds, but times it out after three seconds.

EXAMPLE2

   use Sys::AlarmCall;
   alarm_call(4,'read',STDIN,$r,5);
   print $r;

makes the read() system call which would block
until some characters are ready to be read from STDIN (after a
return), and then should try to read up to 5 characters.
However, the timeout for 4 seconds means that this call
will return after 4 seconds if nothing is read by then.

EXAMPLE3

   use Sys::AlarmCall;
   sub do1 {
	print "Hi, this is do1\n";
	select(undef,undef,undef,10);
	print "Bye from do1\n"
   }
   sub do2 {
	print "Hi, this is do2\n";
	alarm_call(5,'do1');
	print "Bye from do2\n"
   }
   sub do3 {
	print "Hi, this is do3\n";
	alarm_call(3,'do2');
	print "Bye from do3\n"
   }
   sub do4 {
	print "Hi, this is do4\n";
	alarm_call(8,'do2');
	print "Bye from do4\n"
   }
   
   foreach $test (('do1','do2','do3','do4')) {
       print "\n$test\n";
       $time = time;
       &$test;
       print "$test completed after ", 
	   time - $time ," seconds.\n";
   }


Explanation of EXAMPLE3:

Where interrupts occur, you will see the 'Hi' statement without the
corresponding 'Bye' statement.

The 'do1' is a simple test that select() works correctly, delaying for
10 seconds. The 'do2' is a simple test of the alarm_call, testing
that the select() is interrupted after 5 seconds. The third and
fourth 'do's are tests of nested calls to alarm_call. 'do3' should
timeout after three seconds, interrupting the call to 'do2' (so we
should see no 'bye' statement from 'do2'). 'do4' on the other hand,
has a timeout of 8 seconds, so 'do2', which it calls and which is set
to timeout and return after 5 seconds, will complete, printing out
its 'bye' statement.

WARNING - using calls to alarm() in nested calls other than through
the Sys::AlarmCall module may lead to inconsistencies. Calls to alarm
BETWEEN calls to alarm_call should be no problem. Any alarms pending will
be reset after a call to alarm_call to the previous setting minus elapsed
time (approx.). The alarm handler is also reset to the previous one.

BUGS: Some perl core calls (like read, sysread) don't cope when fed
their args as an array. alarm_call explicitly states up to six
arguments so that the perl compiler reads these correctly, but
any core functions which take more than six arguments as minimum
is not accepted as valid by the compiler even if the correct
number of arguments are passed. So consequently, if you want to
time out on these specifically, you may need to wrap them in
a subroutine.

=head1 AUTHOR

Jack Shirazi (CPAN ID 'JACKS')

  Copyright (c) 1995 Jack Shirazi; 2003 Ask Bjoern Hansen. All rights
  reserved.  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.
