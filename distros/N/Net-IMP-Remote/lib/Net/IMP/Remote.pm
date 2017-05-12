use strict;
use warnings;

package Net::IMP::Remote;
use base 'Net::IMP::Base';
use fields qw(factory pid interface);
use Net::IMP::Remote::Client;
use Net::IMP::Remote::Connection;
use Net::IMP::Remote::Protocol;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Net::IMP::Debug;
use Scalar::Util 'weaken';
use Carp;

our $VERSION = '0.009';

my $INETCLASS = 'IO::Socket::INET';
BEGIN {
    for(qw(IO::Socket::IP IO::Socket::INET6)) {
	eval "require $_" or next;
	$INETCLASS = $_;
	last;
    }
}

sub validate_cfg {
    my ($class,%args) = @_;
    my @err;
    push @err,"no address given" if ! delete $args{addr};
    push @err,"invalid value for 'fail'" 
	if ( delete $args{fail} // 'hard' ) !~m{^(soft|hard)$};
    eval { Net::IMP::Remote::Protocol->load_implementation(delete $args{impl})}
	or push @err,$@;
    return (@err,$class->SUPER::validate_cfg(%args));
}

sub new_factory {
    my ($class,%args) = @_;
    my $self = $class->SUPER::new_factory(%args);
    $self->_factory();
    return $self;
}

sub set_interface {
    my ($self,$if) = @_;
    $self->{interface} = $if; # store for reconnects
    return $self->_factory->set_interface($if);
}

sub get_interface {
    my $self = shift;
    return $self->_factory->get_interface(@_);
}

sub new_analyzer {
    my ($self,%args) = @_;
    return $self->_factory->new_analyzer(%args);
}

sub _factory {
    my $self = shift;

    # close and reconnect after fork
    my $f = $self->{factory};
    $f = undef if $f and $self->{pid} != $$;
    if ( ! $f ) {
	$f = $self->{factory} = $self->_reconnect();
	$self->{pid} = $$;
    }
    # successful connected to IMP server
    return $f if $f;

    # return dummy factory object which supports no interface
    # and where each analyzer just issues IMP_FATAL
    return Net::IMP::Remote::_Fail->new_factory(%{ $self->{factory_args}});
}

sub _reconnect {
    my $self = shift;
    my $addr = $self->{factory_args}{addr} or croak("no addr given");
    my $ev = $self->{factory_args}{eventlib} or croak(
	"data provider does not offer integration into its event loop with eventlib argument");
    my $fd = $addr =~m{/} 
	? IO::Socket::UNIX->new(Peer => $addr, Type => SOCK_STREAM, Timeout => 10) 
	: $INETCLASS->new( PeerAddr => $addr, Timeout => 10)
	or return;
    $fd->blocking(0);
    debug("connected to $addr");
    my $conn = Net::IMP::Remote::Connection->new($fd,0,
	impl => $self->{factory_args}{impl}, 
	eventlib => $ev,
    );
    weaken(my $wself=$self);
    $conn->onClose(sub {
	my $why = shift;
	$wself->{factory} = undef; # reconnect on new_analyzer
    });
    my $factory = Net::IMP::Remote::Client->new_factory(
	%{ $self->{factory_args}},
	conn => $conn, 
    ) or die "cannot create factory";

    # set last used interface again
    $factory = $factory->set_interface($self->{interface}) 
	if $self->{interface};
    return $factory;
}


{
    package Net::IMP::Remote::_Fail;
    use base 'Net::IMP::Base';
    use Net::IMP qw(:DEFAULT :log);
    sub set_interface { return shift } # no change factory
    sub get_interface { return ()    } # we don't support anything
    sub data { return }

    sub new_analyzer {
	my $class = shift;
	my $self = $class->SUPER::new_analyzer(@_) or return;
	my $fail = $self->{factory_args}{fail} || 'hard';
	my $err = $self->{factory_args}{connect_error} || $!;
	$self->run_callback(
	    $fail eq 'soft' ? (
		[ IMP_LOG,0,0,0,IMP_LOG_ERR,
		    "connect to IMP server failed ($err): pass all" ],
		[ IMP_PASS,0,IMP_MAXOFFSET ],
		[ IMP_PASS,1,IMP_MAXOFFSET ],
	    ):( 
		[ IMP_FATAL,"connect to IMP server failed ($err)" ] 
	    )
	);
	return $self;
    }
}

1;
__END__

=head1 NAME 

Net::IMP::Remote - connect to IMP plugins outside the process

=head1 SYNOPSIS

  perl imp-relay.pl ... -M Net::IMP::Remote=addr=imp-host:2000 ...

=head1 DESCRIPTION

L<Net::IMP::Remote> works as a normal IMP analyzer, but sends all API calls to
a server process, which might be on the local or on a different machine.
Current implementation feature connection using UNIX domain sockets or TCP
sockets.

The RPC functionality is described in L<Net::IMP::Remote::Protocol>.
L<Net::IMP::Remote::Connection> implements interactions using the defined RPCs
over a flexible wire protocol. The default wire implementation using the
Storable library is done in L<Net::IMP::Remote::Storable>. There is an
alternative implementation with the Sereal library in
L<Net::IMP::Remote::Sereal>.
L<Net::IMP::Remote::Client> and L<Net::IMP::Remote::Server> implement the
client and server side of the connection, while L<Net::IMP::Remote> finally
implements the usual IMP interface, so that this plugin can be used whereever
other IMP plugins can be used, although it's used best in data providers
offering an integration into their event loop.

=head2 Arguments

This proxy IMP analyzer features the following arguments

=over 4

=item addr ip:port|/path

This describes the address, where the IMP server can be reached. This can be an
absolute path (UNIX domain socket) or C<ip:port>. IPv6 is supported if
C<IO::Socket::IP> or C<IO::Socket::INET6> are available.

=item fail 'hard'|'soft'

This defines the behavior in case the connection to the IMP server fails when
creating a new analyzer object for a connection. On the default 'hard' a failed
connection will result in an analyzer returning only C<IMP_FATAL>, thus
blocking all data.
In case of 'soft' the analyzer will return an error log message but then issue
an C<IMP_PASS> for both directions, so that data pass unchanged.

If the connections to the IMP server breaks while analysis is already taking
process it will currently fail hard.

=back

=head2 Implementation and Overhead

Unlike other solutions like ICAP, IMP tries to keep the overhead small.
A new connection to the IMP RPC server is done once, when the factory object is
created. Traffic for all analyzers created from the factory will be multiplexed
over the same connection, thus eliminating costly connection setup.
All RPC calls, except the initial get_interface after creating the factory
object, are asynchronous, because they don't need an immediate reply to
continue operation.

=head2 Integration Into Data Providers Event Loop

While it is possible to use L<Net::IMP::Remote> without an event loop it is
slower, because all read and write operation will block until they are done.
But the data provider might provide a simple event loop object within the
C<new_factory> call:

  my $factory = Net::IMP::Remote->new_factory(
    addr => 'host:port',
    eventlib => myEventLib->new
  );

The event lib object should implement the following simple interface

=over 4

=item ev->onread(fh,callback)

If callback is given it will set it up as a read handler, e.g. whenever the
file handle gets readable the callback will be called without arguments.
If callback is not given it will remove any existing callback, thus ignoring if
the file handle gets readable.

=item ev->onwrite(fh,callback)

Similar to C<onread>, but for write events

=item ev->timer(after,callback,[interval]) -> timer_obj

This will setup a timer, which will be called after C<after> seconds and call
C<callback>. If C<interval> is set it will reschedule the timer again and again
to be called every C<interval> seconds. 
Ths method returns an object C<timer_obj>. If this object gets destroyed the
timer will be canceled.

=back

=head1 TODO

See TODO file in distribution

=head1 SEE ALSO

L<Storable>
L<Sereal::Encoder>
L<Sereal::Decoder>

=head1 AUTHOR

Steffen Ullrich
