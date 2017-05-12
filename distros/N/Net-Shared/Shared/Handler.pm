use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.17";

package Net::Shared::Handler;
use IO::Socket;
use Storable qw(freeze thaw);
use Carp;

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self       = {};
    $self->{vars}  = {};
    $self->{debug} = scalar @_ ? shift : 0;
    if ($self->{debug})
    {
        print "Constructor for Handler.\n\n";
    }
    bless ($self, $class);
}

sub cleanup
{
    my ($self, $return_value) = @_;
    $self->destroy_all;
    return $return_value;
}

sub add
{
    my ($self, @vars) = @_;
    print "Adding Objects:\n" if ($self->{debug});
    foreach my $var (@vars)
    {
        $self->{vars}->{$$var->{name}.$$var->{ref}} = $var;
        print "\t", $$var->{debug}, " added.\n" if ($self->{debug});
    }
    print "\n" if ($self->{debug});
}

sub remove
{
    my ($self, @vars) = @_;
    foreach my $var (@vars)
    {
        my $temp = $$var->{name}.$$var->{ref};
        $$var->destroy_variable;
        delete $self->{vars}->{$temp};
    }
}

sub store
{
    my ($self, $var, $data) = @_;
    $var = $self->{vars}->{$var->{name}.$var->{ref}};
    my $address = exists($$var->{address}) ? $$var->{address} : '127.0.0.1';

    my $send = IO::Socket::INET->new
                                   (
                                     Proto    => 'tcp',
                                     PeerAddr => $address,
                                     PeerPort => $$var->{port}
                                   ) or croak( $self->cleanup($!) );

    $send->autoflush(1);

    if ($$var->{debug})
    {
        print "Connected to ", $$var->{ref}, " for storing:\n";
        print "\tPeerhost: ",  $send->peerhost, "\n";
        print "\tPeerport: ",  $send->peerport, "\n";
        print "\tLocalhost: ", $send->sockhost, "\n";
        print "\tLocalport: ", $send->sockport, "\n\n";
    }

    my $header = $$var->build_header;
    my $serialized_data = $$var->prepare_data(\$data);

    my $bytes = syswrite($send, $header.$serialized_data, length($serialized_data) + length($header));
    $send->close;
    return $bytes;
}

sub retrieve
{
    my ($self, $var) = @_;
    $var = $self->{vars}->{$var->{name}.$var->{ref}};

    my $address = exists($$var->{address}) ? $$var->{address} : '127.0.0.1';
    my $message = IO::Socket::INET->new
                                    (
                                     Proto     => 'tcp',
                                     PeerPort  => $$var->{port},
                                     PeerAddr  => $address
                                    ) or die ( $self->cleanup($!) );

    $message->sockopt (SO_REUSEADDR, 1);
    $message->sockopt (SO_LINGER, 0);

    $message->autoflush(1);
    my $port = $message->sockport;
    if ($$var->{debug})
    {
        print "Connected to ", $$var->{ref}, " for retrieving:\n";
        print "\tPeerhost: ",  $message->peerhost, "\n";
        print "\tPeerport: ",  $message->peerport, "\n";
        print "\tLocalhost: ", $message->sockhost, "\n";
        print "\tLocalport: ", $message->sockport, "\n\n";
    }

    my $header = $$var->build_header;
    syswrite($message, $header.$$var->{response}, length($$var->{response})+length($header));
    $message->close;

    $message = IO::Socket::INET->new
                                 (
                                  Listen    => SOMAXCONN,
                                  LocalPort => $port,
                                  Reuse     => 1,
                                  LocalAddr => '127.0.0.1',
                                 ) or croak ( $self->cleanup($!) );
    if ($$var->{debug})
    {
        print "Listening for ", $$var->{ref}, ":\n";
        print "\tLocalport: ",  $message->sockport, "\n\n";
    }
    while (my $connection = $message->accept)
    {
        if ($$var->{debug})
        {
            print "Recieved a connection from ", $$var->{ref}, ":\n";
            print "\tPeerhost: ",  $connection->peerhost, "\n";
            print "\tPeerport: ",  $connection->peerport, "\n";
            print "\tLocalhost: ", $connection->sockhost, "\n";
            print "\tLocalport: ", $connection->sockport, "\n\n";
        }

        my $sent = <$connection>;
        $connection->close if $connection->connected;
        $message->close;
        return $self->inflate_data($sent);
    }
    $message->close if $message->connected;
}

sub set_remote_port
{
    my ($self, $var, $port) = shift;
    $$var->set_port($port);
}

sub set_remote_addr
{
    my ($self, $var, $addr) = shift;
    $$var->set_addr($addr);
}

sub destroy_all
{
    my $self=shift;
    print "Destroying variables: \n" if $self->{debug};
    while ( my($key,$value) = each(%{$self->{vars}}))
    {
        my $temp = $$value->{name}.$$value->{ref};
        my $temp1 = $$value->{debug} if $self->{debug};
        $$value->destroy_variable;
        delete $self->{vars}->{$temp};
        print "\t", $temp1, " destroyed.\n" if $self->{debug};
    }
    print "\n" if $self->{debug};
}

sub inflate_data
{
    my ($self,$data) = @_;
    $data = join('',map(chr,split(/\*/,$data)));
    $data = thaw($data);
    return $$data;
}

sub DESTROY
{
    my $self = shift;
    $self->destroy_all;
}

"JAPH";