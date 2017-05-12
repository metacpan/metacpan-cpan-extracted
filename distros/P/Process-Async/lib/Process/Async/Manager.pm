package Process::Async::Manager;
$Process::Async::Manager::VERSION = '0.003';
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

=head1 NAME

Process::Async::Manager - handle async background process

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $pm = Process::Async::Manager->new;
 my $child = $pm->spawn(
  worker_class => 'Some::Worker::Class',
 );
 $child->stdio->write('start');

=head1 DESCRIPTION

Look in examples/ in the source distribution.

=cut

use curry;
use Carp qw(confess);

=head1 METHODS

=cut

=head2 configure

Applies our configuration. Currently accepts:

=over 4

=item * worker - either the name of the subclass used for instantiating a worker,
or an existing instance, or a coderef which will return a suitable L<Process::Async::Worker>
instance

=item * child - either the name of the subclass used for instantiating a child,
or an existing instance, or a coderef which will return a suitable L<Process::Async::Child>
instance

=back

=cut

sub configure {
	my ($self, %args) = @_;
	$self->{worker} = delete $args{worker} if exists $args{worker};
	$self->{child} = delete $args{child} if exists $args{child};
	$self->SUPER::configure(%args);
}

=head2 worker

Accessor for the L<Process::Async::Worker> generator/class/instance.

=cut

sub worker { shift->{worker} }

=head2 child

Accessor for the L<Process::Async::Child> generator/class/instance.

=cut

sub child { shift->{child} }

=head2 spawn

Spawn a child. Returns a L<Process::Async::Child> instance.

Can take worker/child params.

=cut

sub spawn {
	my ($self, %args) = @_;
	die "Need to be added to an IO::Async::Loop or IO::Async::Notifier first" unless $self->loop;

	# Use the same loop subclass in the child process as we're using
	my $loop_class = ref($self->loop);

	my $worker = delete $args{worker};
	$worker ||= $self->worker;

	my $child = delete $args{child};
	$child ||= $self->child || 'Process::Async::Child';
	$child = $child->() if (ref $child // '') eq 'CODE';
	$child = $child->new unless ref $child;

	$self->debug_printf("Starting %s worker via %s child with %s loop", ref($worker), ref($child), $loop_class);

	# Provide the code and a basic STDIO handler
	$child->configure(
		stdio => {
			via => 'pipe_rdwr',
			on_read => $child->curry::on_read,
		},
		code => sub {
			# (from here, we're in the fork)
			my $loop = $IO::Async::Loop::ONE_TRUE_LOOP = $loop_class->new;
			$self->debug_printf("Loop %s initialised", $loop);
			$worker = $worker->() if (ref $worker // '') eq 'CODE';
			$worker = $worker->new unless ref $worker;

			$loop->add(
				$worker
			);
			$self->debug_printf("Running worker %s", $worker);
			my $exit = $worker->run($loop);
			$self->debug_printf("Worker %s ->run completed with %d", $worker, $exit);
			return $exit;
		}
	);
	$self->add_child($child);
	$child
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014-2015. Licensed under the same terms as Perl itself.
