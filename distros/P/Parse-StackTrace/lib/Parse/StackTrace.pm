package Parse::StackTrace;
use 5.006;
use Moose;
use Parse::StackTrace::Exceptions;
use Exception::Class;
use List::Util qw(max min);
use Scalar::Util qw(blessed);

our $VERSION = '0.08';

has 'threads'    => (is => 'ro', isa => 'ArrayRef[Parse::StackTrace::Thread]',
                     required => 1);
has 'binary'     => (is => 'ro', isa => 'Str|Undef');
has 'text_lines' => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

# Defaults for StackTrace types that don't define these.
use constant BIN_REGEX => '';
use constant IGNORE_LINES => {};

our $WHITESPACE_ONLY = qr/^\s*$/;

#####################
# Parsing Functions #
#####################

sub parse {
    my $class = shift;
    # If you call parse() directly on this class, then we use the "type"
    # parameter to determine what type of StackTrace we're parsing.
    if ($class eq 'Parse::StackTrace') {
        my %params = @_;
        my $types = $params{'types'};
        die "You must specify trace types" if !$types || !scalar @$types;
        my $trace;
        foreach my $type (@$types) {
            my $parser = $class->_class("Type::$type");
            $trace = $parser->parse(@_);
            return $trace if $trace;
        }
        
        return undef;
    }
    
    # For subclasses
    return $class->_do_parse(@_);
}

sub _do_parse {
    my ($class, %params) = @_;
    my $text  = $params{text};
    my $debug = $params{debug};
    
    die "You must specify a value for the 'text' argument" if !defined $text;
    if ($text !~ $class->HAS_TRACE) {
        return undef;
    }
    
    my $binary;
    if ($class->BIN_REGEX and $text =~ $class->BIN_REGEX) {
        $binary = $1;
    }

    my ($threads, $trace_lines) = $class->_parse_text($text, $debug);
    my $trace = $class->new(threads => $threads, binary => $binary,
                            text_lines => $trace_lines);
    return $trace;
}

sub _parse_text {
    my ($class, $text, $debug) = @_;
   
    my @lines = split(/\r?\n/, $text);
    my @threads;
    my $default_thread = $class->thread_class->new();
    my $current_thread = $default_thread;
    my $current_end_line = 0;
    print STDERR "Current Thread: Default\n" if $debug;
    while (scalar @lines) {
        my $lines_start_size = scalar @lines;
        
        my $frame_lines = $class->_get_next_trace_block(\@lines);
        
        my $lines_read = $lines_start_size - scalar(@lines);
        my $current_start_line = $current_end_line + 1;
        $current_end_line += $lines_read;
        
        if ($debug) {
            my $joined_lines = join("\n", @$frame_lines);
            print STDERR "Trace Line(s) $current_start_line-$current_end_line:",
                         " [$joined_lines]\n";
        }
        
        next if (scalar(@$frame_lines) == 1
                 and ($frame_lines->[0] =~ $WHITESPACE_ONLY
                      or $class->_ignore_line($frame_lines->[0])));

        $current_thread = $class->_handle_block(
            start_line_number => $current_start_line,
            end_line_number   => $current_end_line,
            frame_lines       => $frame_lines,
            thread  => $current_thread,
            threads => \@threads,
            debug   => $debug,
            lines   => \@lines,
        );
    }
    
    # Don't include any threads that don't have frames.
    @threads = grep { scalar @{ $_->frames } } @threads;
    
    @threads = ($default_thread) if not @threads;

    my @thread_starts = $threads[0]->starting_line;
    # Sometimes default_thread isn't in the final @threads, but if we parsed
    # frames into it, then it should be considered part of the trace text.
    if ($default_thread->has_starting_line) {
        push(@thread_starts, $default_thread->starting_line);
    }
    my $trace_start = min(@thread_starts) - 1;
    my $trace_end = $threads[-1]->ending_line - 1;
    my @trace_lines = (split(/\r?\n/, $text))[$trace_start..$trace_end];

    return (\@threads, \@trace_lines);
}

sub _handle_block {
    my ($class, %params) = @_;
    my ($frame_lines, $current_thread, $threads, $start, $end, $lines, $debug) =
        @params{qw(frame_lines thread threads start_line_number end_line_number
                   lines debug)};

    if (my ($number, $description) = $class->_line_starts_thread($frame_lines->[0])) {
        $current_thread = $class->thread_class->new(
            number => $number, description => $description,
            starting_line => $start);
        push(@$threads, $current_thread);
        print STDERR "Current Thread: " . $current_thread->number . "\n"
            if $debug;
    }
    elsif ($frame_lines->[0] =~ $class->HAS_TRACE) {
        # For the default thread, we have to set its starting line as soon
        # as we parse a frame in it.
        if (!$current_thread->has_starting_line) {
            $current_thread->starting_line($start);
        }
        
        my $thread_end = $end;
        # If the next line is ignored, it's still part of the thread
        # in terms of its textual content, so we want to make the thread
        # end on that line instead.
        if ($lines->[0] and $class->_ignore_line($lines->[0])) {
            $thread_end++;
        }
        $current_thread->ending_line($thread_end);

        my $frame;
        eval {
            $frame = $class->frame_class->parse(lines => $frame_lines,
                                                debug => $debug);
        };
        my $e;
        if ($e = Exception::Class->caught('Parse::StackTrace::Exception::NotAFrame')) {
            warn $e;
        }
        elsif ($e = Exception::Class->caught) {
            (blessed $e and $e->isa('Exception::Class')) ? $e->rethrow : die $e;
        }
        else {
            $current_thread->add_frame($frame);
        }
    }
    
    return $current_thread;
}

sub _get_next_trace_block {
    my ($class, $lines) = @_;
    my @frame_lines = (shift @$lines);
    if ($frame_lines[0] =~ $class->HAS_TRACE) {
        while (@$lines) {
            my $next_line = $class->_get_next_frame_line($lines);
            last if not $next_line;
            push(@frame_lines, $next_line);
        }
    }
    
    return \@frame_lines;
}

# Returns the next line only if it's a *fragment* of a stack frame.
# If it's the start of a new frame, a new thread, or a line that we
# ignore, then we return nothing.
sub _get_next_frame_line {
    my ($class, $lines) = @_;
    my $line = $lines->[0];
    if ($class->_next_line_ends_frame($line)) {
        return undef
    }
    return shift @$lines
}

sub _next_line_ends_frame {
    my ($class, $line) = @_;
    if ($line =~ $WHITESPACE_ONLY or $class->_ignore_line($line)
        or $line =~ $class->HAS_TRACE
        or $class->_line_starts_thread($line))
    {
        return 1;
    }
    return 0;
}

# By default we don't support threads.
sub _line_starts_thread { return (); }

sub _ignore_line {
    my ($class, $line) = @_;
    return grep($_ eq $line, $class->IGNORE_LINES) ? 1 : 0;
}

#####################
# Complex Accessors #
#####################

sub text {
    my $self = shift;
    return join("\n", @{ $self->text_lines });
}

sub thread_number {
    my ($self, $number) = @_;
    my ($thread) = grep { defined $_->number and $_->number == $number }
                        @{ $self->threads };
    return $thread;
}

sub thread_with_crash {
    my $self = shift;
    foreach my $thread (@{ $self->threads }) {
        return $thread if defined $thread->frame_with_crash;
    }
    return undef;
}

####################
# Subclass Helpers #
####################

sub thread_class { return shift->_class('Thread') }
sub frame_class  { return shift->_class('Frame')  }

sub _class {
    my ($invocant, $what) = @_;
    my $class = ref $invocant || $invocant;
    my $module = $class . '::' . $what;
    my $file = $module;
    $file =~ s{::}{/}g;
    eval { require "$file.pm" }
        || die("Error requiring $module: $@");
    return $module;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace - Parse the text representation of a stack trace into an
object.

=head1 SYNOPSIS

 my $trace = Parse::StackTrace->parse(types => ['GDB', 'Python'],
                                      text => $text,
                                      debug => 1);
 my $thread = $trace->thread_number(1);
 my $frame = $thread->frame_number(0);

=head1 DESCRIPTION

This module parses stack traces thrown by different types of languages
and converts them into an object that you can use to get information
about the trace.

If the text you're parsing could contain different types of
stack traces, then you should call L</parse> in this module to parse
your text. (So, you'd be calling C<< Parse::StackTrace->parse >>.)

Alternately, if you know you just want to parse one type of trace (say,
just GDB traces) you can call C<parse()> on the Type class you want.
For example, if you just want to parse GDB traces, you could call
C<< Parse::StackTrace::Type::GDB->parse >>. The only difference between
the Type-specific C<parse> methods and L</parse> in this module is
that the Type-specific C<parse> methods don't take a C<types> argument.

=head1 PARTS OF A STACK TRACE

Stack traces have two main components: L<Threads|Parse::StackTrace::Thread>
and L<Frames|Parse::StackTrace::Frame>. A running program can have multiple
threads, and then each thread has a "stack" of functions that were called.
Each function is a single "frame". A frame also can contain other
information, like what arguments were passed to the function, or what
code file the frame's function is in.

You access Threads by calling methods on the returned StackTrace object
you get from L</parse>.

You access Frames by calling methods on Threads.

=head1 CLASS METHODS

=head2 C<parse>

=over

=item B<Description>

Takes a block of text, and if there are any valid stack traces in that
block of text, it will find the first one and return it.

=item B<Parameters>

This method takes the following named parameters:

=over

=item C<text>

A string. The block of text that you want to find a stack trace in.

=item C<types>

An arrayref containing strings. These are the types of traces that you
want to find in the block. Traces are searched for in the order specified,
so if there is a trace of the first type in the list, inside the text, then
the second type in the list will be ignored, and so on.

Currently valid types are: C<GDB>, C<Python>

Types are case-sensitive.

=item C<debug>

Set to 1 if you want the method to output detailed information about
its parsing.

=back

=item B<Returns>

An object that is a subclass of Parse::StackTrace, or C<undef> if no
traces of any of the specified types were found in the list.

=back


=head1 INSTANCE ATTRIBUTES

These are methods of Parse::StackTrace objects that return data.
You should always call them as methods (never like
C<< $object->{attribute} >>).

=head2 C<binary>

Some stack traces contain information on what binary threw the stack trace.
If the parsed trace had that information, this will be a string specifying
the binary that threw the stack trace. If this information was not in
the stack trace, then this will be C<undef>.

=head2 C<threads>

An arrayref of L<Parse::StackTrace::Thread> objects, representing the
threads in the trace. Sometimes traces have only one thread, in which
case that will simply be C<< threads->[0] >>.

The threads will be in the array in the order that they were listed
in the trace.

There is always at least one thread in every trace.

=head2 C<text>

Returns the text of just the trace, with line endings converted to
just CR. (That is, just C<\n>, never C<\r\n>.)

=head2 C<text_lines>

An arrayref containining the lines of just the trace, without line endings.

=head1 INSTANCE METHODS

These are additional methods to get information about the stacktrace.

=head2 C<thread_number>

Takes a single integer argument. Returns the thread with that number, from
the L</threads> array. Thread numbering starts at 1, not at 0 (because this
is how GDB does it, and GDB was our first implementation).

Note that if you want a particular-numbered thread, you should use
this method, not L</threads>, because it's possible somebody could have
a stack trace with the threads out of order, in which case C<< threads->[0] >>
would not be "Thread 1".

=head2 C<thread_with_crash>

Returns the first thread where C<Parse::StackTrace::Thread/frame_with_crash>
is defined, or C<undef> if no threads contain a C<frame_with_crash>.

=head1 SEE ALSO

The various parts of a stack trace:

=over

=item L<Parse::StackTrace::Thread>

=item L<Parse::StackTrace::Frame>

=back

The different types of stack traces we can parse (which have special methods
for the specific sort of data available in those traces that aren't available
in all traces):

=over

=item L<Parse::StackTrace::Type::GDB>

=item L<Parse::StackTrace::Type::Python>

=back

=head1 TODO

Eventually we should be able to parse out multiple stack traces from
one block of text. (This will be the list-context return of L</parse>.)

=head1 BUGS

There are no known issues with this module. It has received extensive
testing, and it should be considered stable.

Any bugs found should be reported to the author by email.

=head1 AUTHOR

Max Kanat-Alexander <mkanat@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Canonical Ltd.

This library (the entirety of Parse-StackTrace) is free software;
you can redistribute it and/or modify it under the same terms as Perl
itself.
