package Net::Async::Memcached::Client;
BEGIN {
  $Net::Async::Memcached::Client::VERSION = '0.001';
}
use strict;
use warnings FATAL => 'all';
use parent qw(Net::Async::Memcached);

use IO::Async::Stream;

=head1 NAME

Net::Async::Memcached::Client - basic L<IO::Async> support for memcached

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

=head1 METHODS

=cut

=head2 new

Instantiate.

Takes the following named parameters:

=over 4

=item * loop - L<IO::Async::Loop> object (required)

=item * host - address to connect to, default localhost

=item * service - port to connect to, default 11211

=back

=cut

sub new {
	my $class = shift;
	my %args = @_;

	my $self = bless {
		host	=> exists($args{host}) ? delete $args{host} : 'localhost',
		service	=> exists($args{service}) ? delete $args{service} : 11211,
	}, $class;

	$self->connect(
		%args,
		host	=> $self->host,
		service	=> $self->service,
	);
	$self->Protocol::Memcached::init;
	return $self;
}

=head2 connect

Connect to the memcached server. Happens automatically if there's no 
=cut

sub connect {
	my $self = shift;
	my %args = @_;
	my $loop = delete $args{loop} or die "Need an IO::Async::Loop object";

# Add one-shot handler for connected event if we were given on_connected
	$self->add_handler_for_event(
		connected	=> sub {
			my $self = shift;
			$args{on_connected}->(@_);
			return 0;
		}
	) if exists $args{on_connected};

	Scalar::Util::weaken(my $weak_loop = $loop);
	$loop->connect(
		host		=> $args{host},
		service 	=> $args{service},
		socktype	=> 'stream',
		on_stream	=> $self->sap(sub {
			my $self = shift;
			my $stream = shift;
			$self->{stream} = $stream;
			$stream->configure(
				on_read => $self->sap(sub {
					my ($self, $stream, $buffref, $eof) = @_;
					return 1 if $self->on_read($buffref);
					return undef;
				})
			);
			$weak_loop->add($stream);
			$self->invoke_event('connected');
		}),
		on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
		on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
	);
}

=head2 host

Accessor for the C<host> information - this is the address we will attempt to connect to.

=cut

sub host { shift->{host} }

1;

__END__

=head1 SEE ALSO

There's a list of alternative memcached modules in L<Protocol::Memcached/SEE ALSO>.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
