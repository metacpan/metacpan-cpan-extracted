package Parse::StackTrace::Type::Python::Thread;
use Moose;

extends 'Parse::StackTrace::Thread';

sub add_frame {
    my $self = shift;
    $self->_unshift_frame(@_);
    my $count = 0;
    foreach my $frame (@{ $self->frames }) {
        $frame->{number} = $count;
        $count++;
    }
}

sub frame_number {
    return $_[0]->frames->[$_[1]];
}

sub frame_with_crash { return $_[0]->frame_number(0) };

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Parse::StackTrace::Type::Python::Thread - A thread from a Python stack
trace.

=head1 DESCRIPTION

This is an implementation of L<Parse::StackTrace::Thread> for Python.

If the parsed stack trace has a line describing the exception that was
thrown (like "Error: timed out"), then the C<description> of this
thread will contain that entire line.