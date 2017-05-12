package Net::Async::TransferFD;
# ABSTRACT: send handles between processes
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.002';

=head1 NAME

Net::Async::TransferFD - support for transferring handles between
processes via socketpair

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use feature qw(say);
 my $loop = IO::Async::Loop->new;
 my $proc = IO::Async::Process->new(
   code => sub { ... },
   fd3 => { via => 'socketpair' },
 );
 $loop->add(my $control = Net::Async::TransferFD->new(
   handle => $proc->fd(3),
   on_fh => sub {
     my $h = shift;
     say "New handle $h - " . join '', <$h>;
   }
 ));
 $control->send(\*STDIN);

=head1 DESCRIPTION

Uses SCM_RIGHTS to pass an open handle from one process to another.
Typically used to hand a network socket off to another process, for
example an accept loop in one process dispatching incoming connections
to other active processes.

=cut

use IO::Async::Handle;

use Socket::MsgHdr qw(sendmsg recvmsg);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC SOL_SOCKET SCM_RIGHTS);
use curry::weak;
use Scalar::Util qw(weaken);
use Variable::Disposition qw(retain_future);

# Not sure of a good value for this but 16 seems low enough
# to avoid problems, we'll split into multiple packets if
# we have more than this number of pending FDs to send.
# On linux the /proc/sys/net/core/optmem_max figure may be
# relevant here - it's 10240 on one test system.
use constant MAX_FD_PER_PACKET => 16;

=head1 METHODS

=cut

=head2 outgoing_packet

Convert a list of handles to a cmsghdr struct suitable for
transferring to another process.

Returns the encoded cmsghdr struct.

=cut

sub outgoing_packet {
	my $self = shift;
	# FIXME presumably this 512 figure should really be calculated,
	# also surely it'd be controllen rather than buflen?
	my $data = pack "i" x @_, map $_->fileno, @_;
	my $hdr = Socket::MsgHdr->new(buflen => length($data));
	$hdr->cmsghdr(SOL_SOCKET, SCM_RIGHTS, $data);
	$hdr
}

=head2 recv_fds

Receive packet containing FDs.

Takes a single coderef which will be called with two
parameters.

Returns $self.

=cut

sub recv_fds {
	my $self = shift;
	my $handler = shift;
	# FIXME more magic numbers
	my $inHdr = Socket::MsgHdr->new(buflen => 512, controllen => 512);
	$handler->($inHdr, sub {
		my ($level, $type, $data) = $inHdr->cmsghdr();
		unpack('i*', $data);
	});
	$self
}

sub handle { shift->{handle} }

=head2 send_queued

If we have any FDs queued for sending, bundle them into a packet
and send them over. Will close the FDs once the send is complete.

Returns $self.

=cut

sub send_queued {
	my $self = shift;
	# Send a single batch at a time
	if(@{$self->{pending} || []}) {
		my @chunk = splice @{$self->{pending}}, 0, MAX_FD_PER_PACKET;
		my @fd = map $_->[0], @chunk;
		my @future = map $_->[1], @chunk;
		$self->debug_printf("Sending %d FDs - %s", scalar(@fd), join ',', map $_->fileno, @fd);
		sendmsg $self->handle->write_handle, $self->outgoing_packet(
			@fd
		);
		$_->close for @fd;
		$_->done for @future;
	}
	# If we have any leftovers, we hope to be called next time around
	$self->handle->want_writeready(0) if $self->handle && ! @{$self->{pending}||[]};
	$self
}

=head2 read_pending

Reads any pending messages, converting to FDs
as appropriate and calling the on_fh callback.

Returns $self.

=cut

sub read_pending {
	my $self = shift;
	$self->recv_fds($self->curry::accept_fds);
}

=head2 accept_fds

Attempts to accept the given FDs from the remote.

Will call L</on_fh> for each received file descriptor after reopening.

=cut

sub accept_fds {
	my ($self, $hdr, $code) = @_;
	defined(recvmsg $self->handle->write_handle, $hdr, 0)
		or $self->debug_printf("Failed to recvmsg - %s", $!);
	unless(length $hdr->{control}) {
		$self->debug_printf("No control data, remote has probably gone away - closing");
		$self->handle->want_readready(0);
		return;
	}

	my @fd = $code->();
	foreach my $fileno (@fd) {
		$self->debug_printf("Opening handle for %d", $fileno);
		open my $fh, '+<&=', $fileno or die $!;
		$self->on_fh($fh);
	}
}

=head2 on_fh

Calls the configured filehandle method if provided (via L</configure>(C<on_fh>)).
=cut

sub on_fh {
	my ($self, $fh) = @_;
	$self->{on_fh}->($fh) if $self->{on_fh};
	$self
}

sub configure {
	my $self = shift;
	my %args = @_;

	$self->{on_fh} = delete $args{on_fh} if exists $args{on_fh};

	if(exists $args{handle}) {
		my $h = delete $args{handle};
		if($h->isa('IO::Async::Handle')) {
			$self->{handle} = $h;
			$self->handle->configure(
				on_write_ready => $self->curry::weak::send_queued,
				on_read_ready => $self->curry::weak::read_pending,
			);
		} else {
			$self->add_child(
				$self->{handle} = IO::Async::Handle->new(
					handle => $h,
					on_write_ready => $self->curry::weak::send_queued,
					on_read_ready => $self->curry::weak::read_pending,
				)
			);
		}
		$self->handle->want_writeready(0);
		$self->handle->want_readready(1);
	};
	$self->SUPER::configure(%args);
}

=head2 send

Sends the given FDs to the remote, returning a L<Future> which will resolve once
all FDs have been transferred.

=cut

sub send {
	my $self = shift;
	my @future;
	for (@_) {
		push @{$self->{pending}}, [
			$_,
			my $f = $self->loop->new_future
		];
		push @future, $f;
	}
	$self->handle->want_writeready(1) if $self->handle;
	retain_future(
		Future->wait_all(@future)
	)
}

sub _remove_from_loop {
	my ($self) = @_;
	$self->stop;
}

sub stop {
	my ($self) = @_;
	(delete $self->{handle})->close if $self->handle;
}


1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Socket::MsgHdr> - we use this to do all the real work

=item * L<File::FDpasser> - another implementation

=back

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2011-2015. Licensed under the same terms as Perl itself.
