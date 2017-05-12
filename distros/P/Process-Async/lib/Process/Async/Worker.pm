package Process::Async::Worker;
$Process::Async::Worker::VERSION = '0.003';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Process::Async::Worker - base class for IO::Async::Loop-using subprocess

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Provides the base class for a worker implementation.

=cut

use curry;

=head1 METHODS

=cut

=head2 run

Subclasses must provide this method.

 sub run {
  my ($self, $loop) = @_;
  $self->send_command('started');
  $loop->add(my $ua = Net::Async::HTTP->new);
  $ua->GET('http://example.com')->get;
 }

=cut

=head2 stdio

Accessor for the STDIO L<IO::Async::Stream>.

=cut

sub stdio { shift->{stdio} }

sub send_command {
	my ($self, $cmd, @data) = @_;
	$self->stdio->write(join(" ", $cmd, @data) . "\n")
}

=head2 on_stdio_read

Handler for incoming STDIN events.

By default, this extracts lines and dispatches the first word as C< cmd_$word >
method, if available, or calls L</on_command> if not found.

Subclasses should override this to provide custom behaviour.

=cut

sub on_stdio_read {
	my ($self, $stream, $buffref, $eof) = @_;
	while($$buffref =~ s/^(.*)\n//) {
		my ($k, $data) = split ' ', $1, 2;
		if(my $method = $self->can('cmd_' . $k)) {
			$method->($self, $data);
		} elsif(my $on_command = $self->can('on_command')) {
			$on_command->($self, $k, $data);
		} else {
			$self->debug_printf("No handler for [%s]", $k);
		}
	}
	$self->on_eof if $eof && $self->can('on_eof');
	0
}

=head2 _add_to_loop

Sets up an L<IO::Async::Stream> for STDIO when we're added to the event loop.

=cut

sub _add_to_loop {
	my ($self, $loop) = @_;
	$self->add_child(
		$self->{stdio} = my $stdio = IO::Async::Stream->new_for_stdio(
			on_read => $self->curry::weak::on_stdio_read,
		)
	);
	$self->debug_printf("Worker has been added to the event loop");
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
