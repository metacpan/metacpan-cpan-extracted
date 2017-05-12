package Parse::StackTrace::Thread;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;

subtype 'Parse::StackTrace::BigInt' => as class_type('Math::BigInt');

has 'frames' => (
    is => 'ro',
    isa => 'ArrayRef[Parse::StackTrace::Frame]',
    default => sub { [] },
    metaclass => 'Collection::Array',
    provides => {
        push    => 'add_frame',
        unshift => '_unshift_frame',
    },
);

has 'number'      => (is => 'ro', isa => 'Int|Parse::StackTrace::BigInt',
                      predicate => 'has_number');
has 'description' => (is => 'ro', isa => 'Str', default => '');

has 'starting_line' => (is => 'rw', isa => 'Int',
                        predicate => 'has_starting_line');
has 'ending_line'   => (is => 'rw', isa => 'Int');

sub frame_number {
    my ($self, $number) = @_;
    # First check if the frame at that array position is the frame
    # we want, as an optimization.
    my $try = $self->frames->[$number];
    if ($try and $try->number and $try->number == $number) {
        return $try;
    }
    my ($frame) = grep { defined $_->number and $_->number == $number }
                       @{ $self->frames };
    return $frame;
}

sub frames_with_function {
    my ($self, $func) = @_;
    my @frames = grep { $_->function eq $func } @{ $self->frames };
    return wantarray ? @frames : $frames[0];
}

sub frame_with_crash {
    my ($self) = @_;
    my ($frame) = grep { $_->is_crash } @{ $self->frames };
    return $frame;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Thread - A single thread (or the only thread) of a stack
trace.

=head1 SYNOPSIS

 my $thread = $trace->thread_number(1);
 
 my $frames = $thread->frames;
 my $thread_number = $thread->number;
 my $thread_description = $thread->description;
 
 my $first_frame = $thread->frame_number(0);
 my @print_frames = $thread->frames_with_function('print');
 my $print_frame = $thread->frames_with_function('print');
 my $crash_frame = $thread->frame_with_crash;

=head1 DESCRIPTION

Represents a single thread of a stack trace (or, for traces that have only
one thread, the one thread of a stack trace). Generally, you access a thread
by calling L<Parse::StackTrace/threads> or L<Parse::StackTrace/thread_number>.

=head1 SIMPLE ACCESSOR METHODS

These are methods that take no arguments and just return information
about the thread.

=head2 C<frames>

An arrayref of L<Parse::StackTrace::Frame> objects. All the frames of
this thread. There should always be at least one frame.

Frames are always ordered from most recent to oldest. So the I<last>
function that was called is always I<first>, in this array.

=head2 C<number>

Some stack traces number their threads. If this particular stack trace
has numbered threads, then this is an integer representing the number of
the thread. If this stack trace doesn't have numbered threads, then
this is C<undef>.

=head2 C<description>

Some stack traces give their threads descriptions--some more information
about the thread--sometimes including a unique identifier. If this
stack trace has thread descriptions, then this is a string representing
the description of the thread. If this stack trace doesn't have
thread descriptions, then this is C<undef>

=head2 C<frame_with_crash>

In some types of traces, the frame where we crashed may not be the
most recent frame. In fact, this thread may not contain the crash
at all.

This method returns the L<Parse::StackTrace::Frame> where we crashed,
or C<undef> if there is no crash in this thread.

=head1 ACCESSOR METHODS THAT TAKE ARGUMENTS

These are methods that take arguments and return information about
this thread.

=head2 C<frame_number>

Takes a single integer argument. Returns the frame with the specified
number. If you are working with a particular type stack trace that
doesn't have numbered frames (like Python), this just returns the
nth frame from L</frames>.

If you are looking for a frame with a particular number, it is more reliable
to use this method than to directly dereference L</frames>, because
theoretically a trace could have a partial stack, missing some frames,
and the 1st item in L</frames> could be frame 4, or something like that.
(There are no known ways of producing a stack like that, but it's still
theoretically possible.)

Frames are numbered from 0 (because that's how GDB does it, and GDB was
our first implementation).

=head2 C<frames_with_function>

Takes a single string argument. Returns all the frames where the named
function is called. The search is case-sensitive.

When called in array context, this returns an the array of
L<Parse::StackTrace::Frame> objects, or an empty array if no frames
were found.

In scalar context, this returns the first frame found (as a
L<Parse::StackTrace::Frame> object), or C<undef> if no frames were found.

=head1 SEE ALSO

You may also want to read the documentation for the specific implementations
of Thread for the various types of traces, which may have more methods than
the basic Thread:

=over

=item L<Parse::StackTrace::Type::GDB::Thread>

=item L<Parse::StackTrace::Type::Python::Thread>

=back