package Net::Async::Memcached;
# ABSTRACT: IO::Async support for the memcached protocol
use strict;
use warnings FATAL => 'all';
use parent qw(Protocol::Memcached Mixin::Event::Dispatch);

our $VERSION = '0.001';

=head1 NAME

Net::Async::Memcached - basic L<IO::Async> support for memcached

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 use strict;
 use warnings;
 use IO::Async::Loop;
 use Net::Async::Memcached::Client;
 my $loop = IO::Async::Loop->new;
 
 # Will begin connection immediately on instantiation
 $mc = Net::Async::Memcached::Client->new(
   host    => 'localhost', # this is the default
   loop    => $loop,
   on_connected => sub {
     my $mc = shift;
     my ($k, $v) = qw(hello world);
     $mc->set(
       $k => $v,
       on_complete  => sub {
         $mc->get(
           $k,
           on_complete  => sub {
             my %args = @_;
             print "Value stored was " . $args{value} . "\n";
             $loop->later(sub { $loop->loop_stop });
           },
           on_error  => sub { die "Failed because of @_\n" }
         );
       }
     );
   }
 );

=head1 DESCRIPTION

Provides basic memcached support - see L<Protocol::Memcached> for a list of available
methods.

This is the parent class used by L<Net::Async::Memcached::Client> and 
L<Net::Async::Memcached::Server>.

=head1 METHODS

=cut

=head2 stream

Accessor for internal L<IO::Async::Stream> object representing the underlying memcached
transport.

=cut

sub stream { shift->{stream} }

=head2 write

Proxies a L<Protocol::Memcached> C<write> request to the underlying transport.

=cut

sub write {
	my $self = shift;
	return $self->stream->write(@_);

# XXX - should really provide some form of auto-reconnection perhaps? thinking along the lines of this in the client:
#	if(my $stream = $self->stream) {
#		$self->stream->write(@_);
#	} else {
#		$self->connect(
#			on_connected	=> sub {
#				my $self = shift;
#				$self->stream->write(@_);
#			}
#		);
#	}
}

=head2 service

Accessor for the C<service> information - this is the port or service name we will attempt to
connect to or listen on.

=cut

sub service { shift->{service} }

1;

__END__

=head1 SEE ALSO

There's a list of alternative memcached modules in L<Protocol::Memcached/SEE ALSO>.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
