package Parse::StackTrace::Type::Python;
use Moose;

extends 'Parse::StackTrace';

our $VERSION = '0.08';

use constant HAS_TRACE => qr/^\s*File\s".+"(?:,|\s+in)/ms;
use constant EXCEPTION_REGEX => qr/
    ^
    (?:Exception \s Type:\s+)?   # Django Format
    \S*(?:Error|Exception)       # Actual Exception
    (?::\s+)|(?:\s+at\b)         # Colon (normal python) or "at" (Django)
/x;

sub thread_number {
    my ($self, $number) = @_;
    return $self->threads->[0] if $number == 1;
    return undef;
}

sub _handle_block {
    my $class = shift;
    my %params = @_;
    my ($frame_lines, $current_thread, $lines, $end, $debug) =
        @params{qw(frame_lines thread lines end_line_number debug)};
    # If we run into the description of the exception, then we're done parsing
    # the trace, provided that we've already parsed some frames.
    my $first_line = $frame_lines->[0];
    if (scalar @{ $current_thread->frames } and $first_line =~ EXCEPTION_REGEX) {
        $current_thread->{description} = trim($first_line);
        print STDERR "Thread Exception: $first_line\n" if $debug;
        pop @$frame_lines;
        # Don't parse anymore.
        @$lines = ();
        $current_thread->ending_line($end);
        return $current_thread;
    }
    
    return $class->SUPER::_handle_block(@_);
}

sub _next_line_ends_frame {
    my $class = shift;
    my ($line) = @_;
    return ($class->SUPER::_next_line_ends_frame(@_)
            or $line =~ EXCEPTION_REGEX);
}

sub trim {
    my $str = shift;
    $str =~ s/^s*//;
    $str =~ s/\s*$//;
    return $str;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Type::Python - A stack trace produced by python

=head1 DESCRIPTION

This is an implementation of L<Parse::StackTrace> for Python tracebacks.

The parser will only parse the I<first> Python stack trace it finds in
a block of text, and then stop parsing.

=head1 SEE ALSO

=over

=item L<Parse::StackTrace::Type::Python::Thread>

=item L<Parse::StackTrace::Type::Python::Frame>

=back