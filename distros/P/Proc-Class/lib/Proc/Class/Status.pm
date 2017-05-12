package Proc::Class::Status;
use strict;
use warnings;
use Any::Moose;
use 5.008001;
use POSIX;

has status => (
    is => 'ro',
);

sub is_exited   { WIFEXITED( $_[0]->status ) }
sub is_signaled { WIFSIGNALED( $_[0]->status ) }
sub is_stopped  { WIFSTOPPED( $_[0]->status ) }
sub termsig     { WTERMSIG( $_[0]->status ) }
sub coredump    { WCOREDUMP( $_[0]->status ) }
sub exit_status { WEXITSTATUS( $_[0]->status ) }

no Any::Moose;
__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Proc::Class::Status - exit status object

=head1 METHODS

=over 4

=item ok $status->is_exited()

returns true if the child terminated normally

=item ok $status->is_signaled()

returns true if the child process was terminated by a signal.

=item ok $status->is_stopped()

returns true if the child process was stopped by delivery of a signal

=item is $status->termsig(), 5;

returns  the  number  of the signal that caused the child process to terminate.

=item ok $status->coredump();

returns true if the child produced a core dump.

=item is $status->exit_status(), 0;

returns  the  exit status of the child.

=back

=head1 SEE ALSO

L<Proc::Class>

