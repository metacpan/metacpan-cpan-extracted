package Parse::StackTrace::Type::GDB;
use Moose;
use Parse::StackTrace::Exceptions;
use Math::BigInt;

extends 'Parse::StackTrace';

our $VERSION = '0.08';

our $WHITESPACE_ONLY = qr/^\s*$/;

use constant HAS_TRACE => qr/
    ^\#\d+\s+                             # #1
    (?:
        (?:0x[A-Fa-f0-9]{4,}\s+in\b)      # 0xdeadbeef in
        |
        (?:[A-Za-z_\*]\S+\s+\()           # some_function_name
        |
        (?:<signal \s handler \s called>)
    )
/mx;
use constant BIN_REGEX => qr/(?:Backtrace|Core) was generated (?:from|by) (?:`|')(.+)/;
                                        #1num   #2name
use constant THREAD_START_REGEX => (
    qr/^Thread (\d+) \((.*)\):$/,
    qr/^\[Switching to Thread (.+) \((.+)\)\]$/,
);

use constant OPEN_PAREN_WITHOUT_CLOSE => qr/\s+\([^\)]*$/;

use constant IGNORE_LINES => (
    'No symbol table info available.',
    'No locals.',
    '---Type <return> to continue, or q <return> to quit---',
);

# If we just have the default thread, return it when asked for Thread 1.
sub thread_number {
    my $self = shift;
    my ($number) = @_;
    if (scalar @{ $self->threads } == 1 and !$self->threads->[0]->has_number
        and $number == 1)
    {
        return $self->threads->[0];
    }
    return $self->SUPER::thread_number(@_)
}

# The most common parsing error during testing was that traces would be
# malformed with extra newlines in the "args" section.
sub _get_next_trace_block {
    my $self = shift;
    my $frame_lines = $self->SUPER::_get_next_trace_block(@_);
    
    my $frame_text = join(' ', @$frame_lines);
    # Check if the trace contains an open-paren after a space, but no
    # close-paren after it.
    if ($frame_text =~ OPEN_PAREN_WITHOUT_CLOSE) {
        my ($lines) = @_;
        my $next_line = $lines->[0];
        
        # If the next line is blank...
        if (defined $next_line and $next_line =~ $WHITESPACE_ONLY) {
            # Then get rid of it and re-parse the block.
            shift @$lines;
            unshift(@$lines, @$frame_lines);
            return $self->_get_next_trace_block(@_);
        }
        
        # Often people will cut up parts of a trace, and the very
        # last frame wil have an open-paren with no close paren.
        # So, if the next line is an end to this frame (or an end to the whole
        # block of text being parsed), then we just have
        # a really bad trace that we should try to deal with anyway by
        # closing the parens on the actual line where the open-paren happens.
        if (!defined $next_line or $self->_next_line_ends_frame($next_line)) {
            my @real_frame_lines;
            
            while (my $line = shift @$frame_lines) {
                if ($line =~ OPEN_PAREN_WITHOUT_CLOSE) {
                    $line .= ')';
                    push(@real_frame_lines, $line);
                    last;
                }
                push(@real_frame_lines, $line);
            }
            
            # Put the remaining lines back into $lines, so that we don't
            # think they're part of the trace.
            unshift(@$lines, @$frame_lines);
            
            return \@real_frame_lines;
        }
    }
    
    return $frame_lines;
}

# We also want to ignore any lines containing gdb commands.
sub _ignore_line {
    my $class = shift;
    my $result = $class->SUPER::_ignore_line(@_);
    return $result if $result;
    my ($line) = @_;
    return $line =~ /^\(gdb\) / ? 1 : 0;
}

sub _line_starts_thread {
    my ($class, $line) = @_;
    foreach my $re (THREAD_START_REGEX) {
        if ($line =~ $re) {
            my ($number, $desc) = ($1, $2);
            if ($number =~ /^0x/ or $number !~ /^\d+$/) {
                # Greater than 0xffffffff needs to be a BigInt for portability.
                $number =~ s/^0x//;
                if (length($number) > 8) {
                    $number = Math::BigInt->new("0x$number");
                }
                else {
                    $number = hex($number);
                }
            }
            return ($number, $desc);
        }
    }
    return ();
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Type::GDB - A stack trace produced by GDB, the GNU
Debugger

=head1 DESCRIPTION

This is an implementation of L<Parse::StackTrace> for GDB traces.

The parser assumes that the text it is parsing contains only one
stack trace, so all detected threads and frames are part of a single
trace.

GDB stack traces come in various levels of quality (some have threads,
some don't, some have symbols, some don't, etc.). The parser deals with
that just fine, but you should not expect all fields of threads and
frames to always be populated.

=head1 SEE ALSO

=over

=item L<Parse::StackTrace::Type::GDB::Thread>

=item L<Parse::StackTrace::Type::GDB::Frame>

=back