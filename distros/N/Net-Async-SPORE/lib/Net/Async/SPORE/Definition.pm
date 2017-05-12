package Net::Async::SPORE::Definition;
$Net::Async::SPORE::Definition::VERSION = '0.003';
use strict;
use warnings;

=head1 NAME

Net::Async::SPORE::Definition - holds information about a SPORE definition

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

No user-serviceable parts inside. See L<Net::Async::SPORE::Loader> instead.

=cut

use JSON::MaybeXS;

=head2 new

Instantiates this object.

=cut

sub new { my $class = shift; bless { @_ }, $class }

sub _transport {
	my $self = shift;
	return $self->{transport} if $self->{transport};

	# If we didn't have a transport, set one up -
	# this is not the recommended usage and will
	# probably change in future.
	require IO::Async::Loop;
	require Net::Async::HTTP;

	my $loop = IO::Async::Loop->new;
	$loop->add(
		$self->{_transport} = Net::Async::HTTP->new
	);
	$self->{_transport}
}

sub _request {
	my ($self, $req) = @_;
	$self->_transport->do_request(
		request => $req
	)->transform(
		done => sub { decode_json(shift->content) }
	)
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
