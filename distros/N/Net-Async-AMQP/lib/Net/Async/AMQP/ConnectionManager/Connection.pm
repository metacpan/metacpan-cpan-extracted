package Net::Async::AMQP::ConnectionManager::Connection;
$Net::Async::AMQP::ConnectionManager::Connection::VERSION = '2.000';
use strict;
use warnings;

=head1 NAME

Net::Async::AMQP::ConnectionManager::Connection - connection proxy object

=head1 VERSION

version 2.000

=head1 METHODS

=head2 new

Instantiate.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class
}

=head2 amqp

Returns the underlying AMQP instance.

=cut

sub amqp { shift->{amqp} }

=head2 manager

Returns our ConnectionManager instance.

=cut

sub manager { shift->{manager} }

=head2 DESTROY

On destruction we release the connection by informing the connection manager
that we no longer require the data.

=cut

sub DESTROY {
	my $self = shift;
	my $conman = delete $self->{manager};
	my $amqp = delete $self->{amqp};
	$conman->release_connection($amqp) if $conman && $amqp;
}

{
our $AUTOLOAD;
sub AUTOLOAD {
	my ($self, @args) = @_;
	(my $method = $AUTOLOAD) =~ s/.*:://;
	die "attempt to proxy unknown method $method for $self" unless $self->amqp->can($method);
	my $code = sub {
		my $self = shift;
		$self->amqp->$method(@_);
	};
	{ no strict 'refs'; *$method = $code }
	$code->(@_)
}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Licensed under the same terms as Perl itself, with additional licensing
terms for the MQ spec to be found in C<share/amqp0-9-1.extended.xml>
('a worldwide, perpetual, royalty-free, nontransferable, nonexclusive
license to (i) copy, display, distribute and implement the Advanced
Messaging Queue Protocol ("AMQP") Specification').
