=head1 NAME

RSH::Logging - Utility for instrumenting code using Log::Log4perl.

=head1 SYNOPSIS

  # In frameworks and other units of code
  use RSH::Logging qw(start_event stop_event);
  ...
  start_event('My piece of work');
  ...
  stop_event();
  
  # At the entry point or "top" of your unit of work
  use RSH::Logging qw(start_event_tracking stop_event_tracking print_event_tracking_results);
  use Log::Log4perl qw(:easy);
  our $logger = get_logger(__PACKAGE__);
  ...
  start_event_tracking($logger, 'My Business Function');
  ...
  stop_event_tracking();
  # print the results to logging
  print_event_tracking_results($logger);
  # print the results to a file (using ">filename")
  print_event_tracking_results($filename);
  # print the results to a file handle
  print_event_tracking_results($fh);
  # print the results to STDERR
  print_event_tracking_results();
  
  # all of which will give you something like:
  TOTAL TIME 0.000766s (1305.483/s)
  .------------------------------+-----------.
  | Event                        | Time      |
  +------------------------------+-----------+
  | + My Business Function       | 0.000766s |
  |   + Reusable foo module      | 0.000615s |
  |     + Database code          | 0.000141s |
  |     + My piece of work       | 0.000191s |
  '------------------------------+-----------'

=head1 DESCRIPTION

RSH::Logging is kind of like poor-man's profiling or dtrace.  It is designed on the same
concepts behind logging packages like Log::Log4perl, that when event tracking is off, there
be little to no overhead incurred by leaving the code in place.  This allows you to 
instrument all your code and frameworks and then dynamically turn on this kind of
profiling information when you need it.

=head2 Best Practices

Below are some best practices to using RSH::Logging.

=head3 1. Only use start_event/stop_event.

The start_event_tracking and stop_event_tracking will mark the "top" or beginning of
a transaction.  If you are truly writing modular code, you will never know when the
beginning of a transaction is until you assemble all your modular code and execute it
as a part of a business function or script.  As a result, you should always defer
marking the transaction boundaries and printing out the results to the final client 
of your code.

For example, if you write a data access object that loads data into objects and a 
generic database framework, both of these should only use start_event and stop_event.
It would be your CGI script that would do the start_event_tracking and stop_event_tracking,
thus marking the total transaction--which your events in the data access object
and the generic database framework would be contained within.  For example,
the final event tree would look something like this:

  TOTAL TIME 0.000766s (1305.483/s)
  .------------------------------+-----------.
  | Event                        | Time      |
  +------------------------------+-----------+
  | + foobar.cgi                 | 0.000766s |
  |   + foobar business function | 0.000615s |
  |     + get database handle    | 0.000141s |
  |     + load foobar by id      | 0.000191s |
  '------------------------------+-----------'

Where "get database handle" is your generic database framework and "load foobar by id"
is your data access object.  You can see that the "foobar.cgi" is the script marking
the transaction via start_event_tracking and stop_event_tracking.

NOTE: if you call start_event_tracking within a block of code that has already
called start_event_tracking, it will be treated as just another call to start_event.

=head3 2. Try to specify the event string when possible.

While RSH::Logging will not do anything if tracking isn't enabled, unnecessary overhead can
be incurred if you don't specify an event string.  If no event string lable is sent to
start_event, caller() is used to find out who called--and that string is used as the
event name.  The call to caller() can be avoided by specifying an event name.  While
caller() is not horribly expensive, it will add to overhead for the total time if
you make enough calls to it.

=head3 3. Always print the results to a logger

Traversing the events and printing them to a table will always have some cost.  You should
allow the logging system to help you mitigate this.  RSH::Logging will output the
event table only if the logger has DEBUG enabled.  If the logger is only printing INFO
levels, the tree will not be processed or printed.

=head3 4. If you don't print the results to a logger, wrap it in a logger check.

If for some reason you don't print the results to the logger, at least wrap
the call to print_event_tracking_results with a check on the logger:

  print_event_tracking_results($event_trace_file) 
          if ($logger->is_debug());

This will prevent you from incurring overhead unnecessarily in production.

=head3 5. Try not to be overly fine-grained in your tracking.

This takes a little trial and error to get the feel for, but can best be illustrated
with an example.

If you have a method "convert_value" that may be called 100 times, putting a 
start_event in the convert_value body will then generate 100 events in your event tree.
This will make it hard to pin-point problem areas in your code, as the event tree will be
100+ events in length (many of them perhaps very small time values).

If you have a situation like this, move the start_event call up one level.  So
for some situation like the following:

  sub convert_value { 
      start_event('convert_value');
      ...
      stop_event(); 
  }

  foreach $element (@elements) {
      convert_value($element);
  } 

Do the following:

  sub convert_value { 
      ...
  }

  start_event('convert_value for elements');
  foreach $element (@elements) {
      convert_value($element);
  }
  stop_event(); 

This will make the final event tree easier to parse.

=cut

package RSH::Logging;

use 5.008;
use strict;
use warnings;

use base qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

=head2 EXPORT

None by default.

You may choose to conditionally export the following:

=over

=item * start_event_tracking

=item * stop_event_tracking

=item * start_event

=item * stop_event

=item * get_event_tracking_results

=item * print_event_tracking_results

=item * event_tracking_in_progress

=back

=cut

our @EXPORT_OK = qw(
					&start_event_tracking
					&stop_event_tracking
					&start_event
					&stop_event
					&get_event_tracking_results
					&print_event_tracking_results
					&event_tracking_in_progress
				   );

our @EXPORT    = qw(
				   );

our $VERSION = '0.4.3';

# use/imports go here
use Log::Log4perl qw(:easy);
our $logger = get_logger(__PACKAGE__);
use Scalar::Util qw(blessed);
use Time::HiRes qw/gettimeofday tv_interval/;
#use Text::SimpleTable;
use RSH::Logging::TextTable;
use IO::Handle;
use IO::File;

# ******************** Class Methods ********************

# The number of rows we automatically start using chunking at.
# A value of <= 0 means no auto-chunking.
our $AUTO_CHUNK_LIMIT = -1;

our $tracking = 0;
our $event_tree;
our $event_count = 0;
our $curr;
our @parents;
our $results;
our $nested_starts = 0;

=head2 FUNCTIONS

=over

=cut

=item event_tracking_in_progress()

Returns 1 if events are currently being tracked, 0 otherwise.

=cut

sub event_tracking_in_progress {
    return $tracking;
}

=item start_event_tracking($logger [, $event_name, $descriptive_note])

Called to signal the beginning of a transaction or the "top" of an event
tree.  This call should be deferred to client code, such as top-level scripts
or business functions.

This call starts event tracking if the supplied logger is processing DEBUG messages.
If the logger is undefined or not processing DEBUG messages, the call returns
immediately and event tracking is not started (all calls to start_event will
exit immediately, preventing any unnecessary overhead in the intrumented
code).

If the logger is processing DEBUG messages, event tracking is started
and a call is made to start_event with the given event name and optional
descriptive note.  If no event name is specified, the results of caller()
are used for the event name.

=cut

sub start_event_tracking {
    my $the_logger = shift;
    my $event = shift;
    my $note = shift;
    
    $event = caller() if not defined($event);
    
    return if (not defined($the_logger));
    if ($tracking) {
        # if we are already tracking, just suck it in like a normal event ...
        start_event($event, $note);
        $nested_starts++;
        return;
    }
    else {
        return unless ($the_logger->is_debug());
    
        # otherwise ...
        $tracking = 1;
        $event_tree = undef;
        $event_count = 0;
        $results = undef;
        $curr = undef;
        @parents = ();
        start_event($event, $note);
        return;
    }
}

=item stop_event_tracking()

Called to signal the end of a transaction or event tree.  This call 
should be deferred to client code, such as top-level scripts or business 
functions.

Stops event tracking and places the current event tree in a variable
to be used by get_event_tracking_results and print_event_tracking_results.
Neither get_event_tracking_results or print_event_tracking_results will
process anything until stop_event_tracking has been called.

=cut

sub stop_event_tracking {
    return unless $tracking;
    if ($nested_starts > 0) {
        $nested_starts--;
        stop_event();
    }
    else {
        while (defined($curr)) {
            stop_event();
        }
        $results = $event_tree;
        $event_tree = undef;
        $tracking = 0;
    }
}

=item print_event_tracking_results($to_target, [$chunk_it])

Prints the event tree to a specified target if event tracking was started
and stopped successfully.  The target may be either a Logger from
Log::Log4perl (recommended and preferred), a filename (in which case
it will be opened for writing via ">filename"), or a file handle (subclass
of IO::Handle).  If event tracking was never started (either because start_event_tracking
was not called or the supplied logger was not processing DEBUG messages) or
is stop_event_tracking was not called, this method will exit
quickly and do nothing.

If there are event tracking results to process, the events will be composed
into a table, with each row's indentation representing whether it is a parent,
peer, or child of the surrounding rows.  The following table is an example:

  .------------------------------+-----------.
  | Event                        | Time      |
  +------------------------------+-----------+
  | + My Business Function       | 0.000766s |
  |   + Reusable foo module      | 0.000615s |
  |     + Database code          | 0.000141s |
  |     + My piece of work       | 0.000191s |
  '------------------------------+-----------'

"My Business Function" is the top-most event, the top of the call stack.
At this point, start_event_tracking was called with an event name of "My Business
Function".  At some point between start_event_tracking and stop_event_tracking,
"Reusable foo module" was called--thus it is a child of "My Business Function".
The module then made two calls, one to "Database code" and another to "My piece
of work"--these two events are peers and children of the module event.  
Other calls may have been made, but they were not instrumented using start/stop_event.

If the second parameter is "true", then chunking will be used if supported for
the C<$to_target> value.  Only filehandles and Log4Perl are supported currently.

=cut

sub print_event_tracking_results {
    return unless defined($results);
    
    my $to = shift;
    my $chunk_it = shift;
    my $fh = undef;
    my $logger = undef;
    if (blessed($to) and $to->isa('Log::Log4perl::Logger')) {
        $logger = $to;
    }
    elsif (blessed($to) and $to->isa('IO::Handle')) {
        $fh = $to;
    }
    elsif (defined($to)) {
        $fh = new IO::File ">$to";
    }
    else {
        $fh = new IO::File ">&STDERR";
    }
    
    return unless defined($fh) or defined($logger);
    return if (defined($logger) and (not $logger->is_debug));
    
    
#    my $t = Text::SimpleTable->new( [ 62, 'Event' ], [ 9, 'Time' ] );
    my $t = RSH::Logging::TextTable->new( [ 62, 'Event' ], [ 9, 'Time' ] );
#    while (defined($ptr)) {
#        $elapsed = tv_interval($ptr->{start}, $ptr->{stop});
#        $ptr->{elapsed} = sprintf( '%fs', $elapsed );
#        $t->row(( q{ } x $depth ) . $ptr->{event}, $ptr->{elapsed} || '??');
#        $ptr = undef;
#    }
    _event_tree_table($t, $results, 0);
    my $elapsed = tv_interval($results->{start}, $results->{stop});
    
    my $av = sprintf '%.3f', ( $elapsed == 0 ? -1 : ( 1 / $elapsed ) );
    $av = '??' if ($av < 0);
    
#    my $msg = "TOTAL TIME ${elapsed}s ($av/s)\n" . $t->draw . "\n";
#    if ($logger) {
#        $logger->debug($msg);
#    }
#    else {
#        print $fh $msg;
#    }
    my $output;
    if ($logger) {
        $output = sub {
            $logger->debug(@_);
        };
    }
    else {
        $output = sub {
            print $fh @_;
        }
    }
    
    my $table_row_count = @{$t->{columns}->[0]->[1]} - 1; # hack lifted form Text::SimpleTable
    if ($chunk_it or (($AUTO_CHUNK_LIMIT > 0) and ($table_row_count >= $AUTO_CHUNK_LIMIT)) ) {
        $output->("TOTAL TIME ${elapsed}s ($av/s)\n");
        $t->draw($output);
        $output->("\n");
    }
    else {
        $output->("TOTAL TIME ${elapsed}s ($av/s)\n" . $t->draw . "\n");
    }
}

=item get_event_tracking_results()

Get the event tree.  The format of the event tree isn't really for
public consumption, but if for some reason you wanted to perform your 
own processing, this is how you would go about doing it.

The event tree is a hash of hashes.  The general structure is:

  {
      event => 'event name',
      note  => 'descriptive note (optional)',
      start => Time::HiRes::gettimeofday() value,
      stop => Time::HiRes::gettimeofday() value,
      children => [array of child event hashes]
  }

This method will return undef if stop_event_tracking has not been called.

=cut

sub get_event_tracking_results {
    return $results;
}

=item get_event_count()

Returns a count of the number of events.  Everytime a start_event is called will
increase the count until another event tracking result is created (i.e. 
stop_event_tracking + start_event_tracking).

=cut

sub get_event_count {
    return $event_count;    
}

=begin private

=cut

=item _event_tree_table()

TODO _event_tree_table description

=cut

sub _event_tree_table {
    my $table = shift;
    my $ptr = shift;
    my $depth = shift;

    my $elapsed = tv_interval($ptr->{start}, $ptr->{stop});
    $ptr->{elapsed} = sprintf( '%fs', $elapsed );
    my $event_str = ( q{  } x $depth ) . "+ ". $ptr->{event};
    $event_str .= " (". $ptr->{note} .")" if defined($ptr->{note});
    $table->row($event_str, $ptr->{elapsed} || '??');
    if (defined($ptr->{children})) {
        foreach my $child (@{$ptr->{children}}) {
            _event_tree_table($table, $child, $depth + 1);
        }
    }        
    return;
}

=end private

=cut

=item start_event([$event_name, $descriptive_note])

Starts an event, using the optional event name and descriptive note.  If tracking has not
been started via start_event_tracking, this methd will return immediately,
incurring no more overhead.  If event tracking has been started, a new
event will be logged in the event tree with its start time (via 
Time::HiRes::gettimeofday()).  If there is already a current event, the new
event is added as a child to the current event, the current event is stored
on the stack, and the new event becomes the current event.

If the event name is not specified, caller() is used to populate the value.

=cut

sub start_event {
    return unless $tracking;
    my $event = shift;
    my $note = shift;
    
    $event = caller() if not defined($event);

    my $new = { event => $event, start => [gettimeofday()], note => $note };
    if (defined($curr)) {
        push @parents, $curr if defined($curr);
        $curr->{children} = [] if not defined($curr->{children});
        push @{$curr->{children}}, $new;
    }
    $curr = $new;
    $event_tree = $curr if not defined($event_tree);
    $event_count++;
}

=item stop_event()

Stops the current event (if there is one).  If event tracking has not been started,
this method returns immediately, incurring no additional overhead.  If the
current event was a child, the parent is popped from the stack and made the new
current event.

=cut

sub stop_event {
    return unless $tracking;
    return unless $curr; # stop a possible error if stuff is messed up
    
    $curr->{stop} = [gettimeofday()];
    $curr = pop @parents;    
}

=back

=cut

# #################### RSH::Logging.pm ENDS ####################
1;

=head1 SEE ALSO

L<Log::Log4perl>

L<http://www.rshtech.com/software/>

=head1 AUTHOR

Matt Luker  C<< <mluker@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Matt Luker C<< <mluker@rshtech.com> >>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__END__
# TTGOG

# ---------------------------------------------------------------------
#  $Log$
# ---------------------------------------------------------------------