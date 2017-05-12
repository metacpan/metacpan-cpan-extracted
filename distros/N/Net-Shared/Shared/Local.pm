use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.17";

package Net::Shared::Local;
use IO::Socket;
use Storable qw(freeze thaw);
use Carp;

sub REAPER
{
    my $waitedpid = wait;
    $SIG{CHLD} = \&REAPER;
}
local $SIG{CHLD} = \&REAPER;

sub new
{
    my ($proto, %config) = @_;

    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);

    $self->{debug}    = exists($config{debug}) ? $config{name} : 0;
    $self->{response} = exists($config{response}) ? $config{response} : "\bl\b";
    $self->{name}     = crypt($config{name}, $config{name});
    $self->{ref}      = $config{name};
    $self->{data}     = "";
    $self->{port}     = 0;
    $self->{lock}     = 0;

    $self->{accept} = defined(@{$config{accept}}) ? [@{$config{accept}}] : [qw(127.0.0.1)];
    my $sock;
    if (!exists($config{port}))
    {
        $sock = IO::Socket::INET->new
                                     (
                                      LocalAddr => 'localhost',
                                      Listen    => SOMAXCONN,
                                      Reuse     => 1,
                                      Proto     => 'tcp'
                                     );

        $sock->sockopt (SO_REUSEADDR, 1);
        $sock->sockopt (SO_LINGER, 0);
        $self->{port} = $sock->sockport;

        while()
        {
             my $temp = IO::Socket::INET->new(
                                               Proto    => 'tcp',
                                               PeerAddr => 'localhost',
                                               PeerPort => $self->{port}
                                              );
                eval{$temp->connected};
                last unless $@;
        }
        $sock->close;
    }

    $self->{port} = $config{port} if exists($config{port});
    $sock = IO::Socket::INET->new
                                 (
                                  LocalPort => $self->{port},
                                  Listen    => SOMAXCONN,
                                  Reuse     => 1,
                                  Proto     => 'tcp'
                                 );
    $sock->autoflush(1);
    if ($config{debug})
    {
        print "Constructor for ", $config{name}, ":\n";
        print "\tType of class: ", $class, "\n";
        print "\tListening on port: ", $self->{port}, "\n";
        print "\tAccepting from addresses:\n";
        foreach my $address (@{$self->{accept}})
        {
            print "\t\t", $address, "\n";
        }
        print "\n";
    }

    croak "Can't fork: $!" unless defined ($self->{child} = fork());
    if ($self->{child} == 0)
    {
        while (my $connection = $sock->accept)
        {
            if ($config{debug})
            {
                print $config{name}, " recieved a connection:\n";
                print "\tPeerhost: ", $connection->peerhost, "\n";
                print "\tPeerport: ", $connection->peerport, "\n";
                print "\tLocalhost: ", $connection->sockhost, "\n";
                print "\tLocalport: ", $connection->sockport, "\n\n";
            }
            do
            {
                $self->{incoming} = <$connection>;

                if (!$self->valid_header)
                {
                    $connection->close;
                    last;
                }
                if (!$self->valid_conn(\$connection))
                {
                    $connection->close;
                    last;
                }
                if ($self->{lock} > 1)
                {
                    $connection->close;
                    last;
                }
                redo if ($self->{lock} > 0);
                $self->{lock} = 1;

                if ($self->{incoming} ne $self->{response})
                {
                    $self->store_data;
                }
                else
                {
                    $self->send_data(\$connection);
                }

                $self->{lock} = 0;
                my $ok;
                $connection->close;
            }
        }
        $sock->close if $sock->connected;
        exit 0;
    }
    else
    {
        return $self
    }
}

sub valid_header
{
    my $self = shift;
    my $valid = crypt($self->{name}, $self->{ref});
    return if (substr($self->{incoming}, 0, length $valid) ne $valid);
    $self->{incoming} = substr($self->{incoming}, length $valid, length($self->{incoming}) - length($valid));
    return 1;
}

sub send_data
{
    my ($self, $connection) = @_;
    my ($address,$port);
    eval{$address = $$connection->peerhost};
    eval{$port = $$connection->peerport};
    $$connection->close;
    my $sock;

    while()
    {
        $sock = IO::Socket::INET->new(
                                      Proto    => 'tcp',
                                      PeerAddr => $address,
                                      PeerPort => $port
                                     ) or next;
        last if $sock->connected;
    }
    $sock->autoflush(1);

    if ($self->{debug})
    {
        print $self->{debug},  " is sending data...\n";
        print "\tPeerhost: ",  $sock->peerhost, "\n";
        print "\tPeerport: ",  $sock->peerport, "\n";
        print "\tLocalhost: ", $sock->sockhost, "\n";
        print "\tLocalport: ", $sock->sockport, "\n\n";
    }

    my $data = $self->get_data;
    syswrite($sock, $data, length $data);
    $sock->close;
}

sub destroy_variable
{
    my $self = shift;
    kill (9, $self->{child});
    undef $self;
}

sub valid_conn
{
    my ($self, $connection) = @_;
    my $check = 0;
    foreach my $accept (@{$self->{accept}})
    {
        $check = 1 if ($accept eq $$connection->peeraddr || $accept eq $$connection->peerhost);
    }
    return $check;
}

sub cleanup
{
    my ($self, $error_value) = @_;
    $self->destroy_variable;
    return $error_value;
}

sub lock
{
    my ($self, $status) = @_;
    $$self->{lock} = $status;
}

sub port
{
    my $self = shift;
    return $self->{port};
}

sub build_header
{
    my $self = shift;
    return crypt(crypt($self->{ref},$self->{ref}),$self->{ref});
}

sub prepare_data
{
    my ($self,$data) = @_;
    my $serialized_data = freeze($data);
    return join('*',map{ord}split(//,$serialized_data));
}

sub store_data
{
    my $self = shift;
    $self->{data} = $self->{incoming};
    $self->{incoming} = '';
}

sub get_data
{
    my $self = shift;
    return $self->{data};
}

sub DESTROY
{
    my $self = shift;
    $self->destroy_variable;
}

"JAPH";