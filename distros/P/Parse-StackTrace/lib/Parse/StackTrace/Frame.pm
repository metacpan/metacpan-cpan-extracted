package Parse::StackTrace::Frame;
use Moose;

has 'function' => (is => 'ro', isa => 'Str', required => 1);
has 'args'     => (is => 'ro', isa => 'Str');
has 'number'   => (is => 'ro', isa => 'Int');
has 'file'     => (is => 'ro', isa => 'Str');
has 'line'     => (is => 'ro', isa => 'Int');
has 'code'     => (is => 'ro', isa => 'Str');
has 'is_crash' => (is => 'ro', isa => 'Bool');

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Frame - A single frame (containing a single function)
from a stack trace.

=head1 SYNOPSIS

 my $frame = $thread->frame_number(0);
 
 my $function = $frame->function;
 my $arguments = $frame->args;
 my $number = $frame->number;
 my $file_name = $frame->file;
 my $file_line = $frame->line;

=head1 DESCRIPTION

Represents a single frame in a stack trace. A frame represents a single
function call in a stack trace. A frame can also contains other
information, like what arguments were passed to the function, or what
code file the frame's function is in.

Usually you get a frame by accessing L<Parse::StackTrace::Thread/frames>
or calling L<Parse::StackTrace::Thread/frame_number>, or using one
of the other methods in L<Parse::StackTrace::Thread> that returns a frame.

=head1 ACCESSORS

These are methods that take no arguments and just return information.

Only L</function> will always have a value. The other attributes are
all optional and may return C<undef> if they have not been specified.

=head2 C<function>

The name of the function that was called in this trace. We return it just
as its written in the stack trace, so we can't guarantee anything about
the format.

=head2 C<args>

A string representing the arguments that were passed to the function.

=head2 C<number>

What number frame this was in the stack trace.

=head2 C<file>

The name of the file that the code of this function lives in. (This
will be the source file, not the binary file, for languages that
differentiate between those two things.) This may be the full path
to the file, or just the file name.

=head2 C<line>

The line number in L</file> where this function was called.

=head2 C<code>

The actual code on L<that line|/line> of L<that file|/file>.

=head2 C<is_crash>

True if this is the frame where we crashed. For example, in a GDB trace,
C<is_crash> true if this is the frame where the signal handler was called.

=head1 SEE ALSO

You may also want to read the documentation for the specific
implementations of Frame for the various types of stack traces that
we parse, because they might have more methods that aren't available
in the generic Frame:

=over

=item L<Parse::StackTrace::Type::GDB::Frame>

=item L<Parse::StackTrace::Type::Python::Frame>

=back