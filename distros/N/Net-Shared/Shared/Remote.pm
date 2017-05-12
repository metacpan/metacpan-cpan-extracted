use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.17";

package Net::Shared::Remote;
use IO::Socket;
use Storable qw(freeze thaw);

sub new
{
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{name}     = crypt($config{name}, $config{name});
    $self->{ref}      = $config{ref};
    $self->{port}     = exists($config{port})     ? $config{port}     : 0;
    $self->{address}  = exists($config{address})  ? $config{address}  : '127.0.0.1';
    $self->{debug}    = exists($config{debug})    ? $config{name}     : 0;
    $self->{response} = exists($config{response}) ? $config{response} : "\bl\b";

    if ($config{debug})
    {
        print "Constructor for ", $config{name}, ":\n";
        print "\tType of class: ", $class, "\n";
        print "\tReferring to Variable: ", $config{ref}, "\n";
        print "\tAddress ", $config{address}, "\n";
        print "\tPort: ", $self->{port}, "\n";
        print "\n";
    }

    bless ($self, $class);
}

sub set_port
{
    my ($self, $port) = @_;
    $self->{port} = $port;
}

sub set_addr
{
    my ($self, $addr) = @_;
    $self->{addr} = $addr;
}

sub destroy_variable
{
    my $self = shift;
    undef $self;
}

sub prepare_data
{
    my ($self,$data) = @_;
    my $serialized_data = freeze($data);
    return join('*',map{ord}split(//,$serialized_data));
}

sub build_header
{
    my $self = shift;
    return crypt(crypt($self->{ref},$self->{ref}),$self->{ref});
}

sub cleanup
{
    my ($self, $error_value) = @_;
    $self->destroy_variable;
    return $error_value;
}

"JAPH";