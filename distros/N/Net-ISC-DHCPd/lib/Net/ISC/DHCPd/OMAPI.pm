package Net::ISC::DHCPd::OMAPI;

=head1 NAME

Net::ISC::DHCPd::OMAPI - Talk to a dhcp server

=head1 SYNOPSIS

    my $omapi = Net::ISC::DHCPd::OMAPI->new(
                    key => "dhcpd secret",
                );

    # connect is lazy
    $omapi->connect

    my $lease = $omapi->new_object(lease => (
                    ip_address => "10.19.83.200",
                ));

    if($lease->read) {
        printf("Got hardware_address=%s from ip_address=%s\n",
            $lease->hardware_address,
            $lease->ip_address,
        );
    }

=head1 DESCRIPTION

This module provides an API to query and possible change the ISC DHCPd
server. The module use OMAPI (Object Management API) which does not
require the server to be restarted for changes to apply. It does
unfortunately support the protocol natively, but instead fork
C<omshell(1)> which this module read and write commands to.

OMAPI is simply a communications mechanism that allows you to manipulate
objects, which is stored in the dhcpd.leases file.

See subclasses for more information about the different objects you can
manipulate:
L<Net::ISC::DHCPd::OMAPI::Failover>,
L<Net::ISC::DHCPd::OMAPI::Group>,
L<Net::ISC::DHCPd::OMAPI::Host>,
and L<Net::ISC::DHCPd::OMAPI::Lease>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item * DHCP_OMAPI_DEBUG=1

This variable will enable debug output.

=back

=cut

use Moose;
use IO::Pty;
use Time::HiRes qw/usleep/;
use Net::ISC::DHCPd::OMAPI::Control;
use Net::ISC::DHCPd::OMAPI::Failover;
use Net::ISC::DHCPd::OMAPI::Group;
use Net::ISC::DHCPd::OMAPI::Host;
use Net::ISC::DHCPd::OMAPI::Lease;
use constant DEBUG => $ENV{DHCP_OMAPI_DEBUG} ? 1 : 0;

our $OMSHELL = 'omshell';

=head1 ATTRIBUTES

=head2 server

This attribute is read-only and holds a string describing the
remote dhcpd server address. Default value is "127.0.0.1".

=cut

has server => (
    is => 'ro',
    isa => 'Str',
    default => '127.0.0.1',
);

=head2 port

This attribute is read-only and holds an integer representing
the remote dhcpd server port. Default value is "7911".

=cut

has port => (
    is => 'ro',
    isa => 'Int',
    default => 7911,
);

=head2 key

This attribute is read-only and holds a string representing the
server secret key. It is in the format C<$name $secret> and the
default value is an empty string. An empty string is used for
servers without a secret to log in.

=cut

has key => (
    is => 'ro',
    isa => 'Str',
    default => '',
);

=head2 errstr

Holds the last know error as a plain string.

=cut

has errstr => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

# meant for internal usage
has _fh => (
    is => 'ro',
    lazy => 1,
    builder => '_build__fh',
    clearer => '_clear__fh',
);

has _pid => (
    is => 'rw',
    isa => 'Int',
);

# fork omshell and return an IO::Pty object
sub _build__fh  {
    my $self = shift;
    my $pty = IO::Pty->new;
    my($pid, $slave);

    pipe my $READ, my $WRITE or confess $!;
    select +(select($WRITE), $|++)[0]; # autoflush

    $pid = fork;

    if(!defined $pid) { # failed
        $self->errstr($@ = $!);
        return;
    }
    elsif($pid) { # parent
        close $WRITE;
        $pty->close_slave;
        $pty->set_raw;
        $self->_pid($pid);

        if(my $error = sysread $READ, my $errno, 255) {
            $! = $errno + 0;
            confess "Could not exec $OMSHELL: $!";
        }
        if(!defined $pty->sysread(my $buffer, 2048)) {
            return;
        }

        return $pty;
    }
    else { # child
        close $READ;
        $pty->make_slave_controlling_terminal;
        $slave = $pty->slave;
        $slave->set_raw;

        open STDIN,  '<&'. $slave->fileno or confess "Reopen STDIN: $!";
        open STDOUT, '>&'. $slave->fileno or confess "Reopen STDOUT: $!";
        open STDERR, '>&'. $slave->fileno or confess "Reopen STDERR: $!";

        { exec $OMSHELL } # block prevent warning
        print $WRITE int $!;
        confess "Could not exec $OMSHELL: $!";
    }
}

# $self->_cmd($cmd);
sub _cmd {
    my $self = shift;
    my $cmd = shift;
    my $pty = $self->_fh;
    my $out = q();
    my $end_time;

    print STDERR "\$ $cmd\n" if DEBUG;

    unless(defined $pty->syswrite("$cmd\n")) {
        $self->errstr($!);
        return;
    }

    $end_time = time + 10;

    BUFFER:
    while(time < $end_time) {
        if(defined $pty->sysread(my $tmp, 1024)) {
            $out .= $tmp;
            $out =~ s/>\s$// and last BUFFER;
        }
        else {
            $self->errstr($!);
            return;
        }
    }

    $out =~ s/^>\s//;

    print STDERR $out if DEBUG;

    return $out;
}

=head1 METHODS

=head2 connect

    $bool = $self->connect;

Will open a connection to the dhcp server. Check L</errstr> on failure.
A connection means starting the program C<omshell(1)> and trying to
log in, if the dhcpd L</key> is set.

=cut

sub connect {
    my $self = shift;
    my @commands = qw/port server/;
    my $buffer;

    push @commands, 'key' if($self->key);

    $self->errstr('');

    for my $attr (@commands) {
        $buffer = $self->_cmd(sprintf "%s %s", $attr, $self->$attr);
        last unless(defined $buffer);
    }

    if($self->errstr) {
        return;
    }
    unless($buffer = $self->_cmd('connect')) {
        return;
    }
    unless($buffer =~ /obj:\s+/) {
        $self->errstr($buffer);
        return;
    }

    return 1;
}

=head2 disconnect

    $bool = $self->disconnect;

Will disconnect from the server. This means killing the C<omshell(1)>
program, which then actually will make sure the connection is shut
down.

=cut

sub disconnect {
    my $self = shift;
    my $retries = 10;

    while($retries--) {
        kill 15, $self->_pid;
        usleep 2e3;
        if(kill 0, $self->_pid) {
            $retries = 1; # make sure it's true
            last;
        }
    }

    unless($retries) {
        return;
    }

    $self->_clear__fh;

    return 1;
}

=head2 new_object

    $object = $self->new_object($type => %constructor_args);

This method will create a new OMAPI object, which can be used to query
and/or manipulate the running dhcpd server.

C<$type> can be "group", "host", or "lease". Will return a new config object.

Example, with C<$type='host'>:

 Net::ISC::DHCPd::Config::Host->new(%constructor_args);

=cut

sub new_object {
    my $self = shift;
    my $type = shift or return;
    my %args = @_;
    my $class = 'Net::ISC::DHCPd::OMAPI::' .ucfirst(lc $type);

    unless($type =~ /^(?:control|failover|group|host|lease)$/i) {
        return;
    }

    return $class->new(parent => $self, %args);
}

=head1 COPYRIGHT & LICENSE

=head1 AUTHOR

See L<Net::ISC::DHCPd>.

=cut
__PACKAGE__->meta->make_immutable;
1;
