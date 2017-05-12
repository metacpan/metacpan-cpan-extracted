package Process::Async::Child;
$Process::Async::Child::VERSION = '0.003';
use strict;
use warnings;

use parent qw(IO::Async::Process);

=head1 NAME

Process::Async::Child - L<IO::Async::Process> subclass for handling communication between parent and worker

=head1 VERSION

version 0.003

=head1 DESCRIPTION

See L<Process::Async>.

=head1 METHODS

=cut

=head2 send_command

Helper for sending a command.

=cut

sub send_command {
	my ($self, $cmd, @data) = @_;
	$self->stdio->write(join(" ", $cmd, @data) . "\n")
}

=head2 on_read

The read handler for processing messages sent by the child process.

=cut

sub on_read {
	my ($self, $stream, $buffref, $eof) = @_;
	while($$buffref =~ s/^(.*)\n//) {
		my ($k, $data) = split ' ', $1, 2;
		$self->debug_printf("Dealing with [%s] command", $k);
		if(my $method = $self->can('cmd_' . $k)) {
			$method->($self, $data);
		} else {
			$self->on_command(
				$k => $data
			);
		}
	}
	$self->debug_printf("Input EOF") if $eof;
	return 0
}

=head2 on_finish

Handle finish events.

=cut

sub on_finish {
	my ($self, $exitcode) = @_;
	$self->debug_printf("Finished - exit code %d", $exitcode);
}

=head2 on_exception

Handle exceptions.

=cut

sub on_exception {
	my ($self, $exception, $errno, $exitcode) = @_;
	$self->debug_printf("Had exception [%s] errno %s exitcode %d", $exception, $errno, $exitcode);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
