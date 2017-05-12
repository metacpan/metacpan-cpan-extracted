package Net::Telnet::Netgear;
use strict;
use warnings;
use warnings::register;
use parent 'Net::Telnet';
use Carp;
use IO::Socket::INET;
use Net::Telnet::Netgear::Packet;
use Scalar::Util ();

our $VERSION = "0.05";

# Whether to die when 'select' is not available. (see 'THE MAGIC BEHIND TIMEOUTS')
our $DIE_ON_SELECT_UNAVAILABLE = 0;
our %NETGEAR_DEFAULTS = (
    prompt  => '/.* # $/',
    cmd_remove_mode => 1,
    exit_on_destroy => 1, # Calls 'exit' when the object is being destroyed
    waitfor => '/.* # $/' # Net::Telnet breaks when there are lines before the prompt
);

sub new
{
    my $class = shift;
    # Our settings, including the default values.
    my $settings = {
        netgear_defaults => 0,
        exit_on_destroy  => 0,
        packet_send_mode => "auto"
    };
    # Packet information. Not populated when there are no named arguments.
    my %packetinfo;
    # The final packet instance. Must be a Net::Telnet::Netgear::Packet.
    my $packet;
    # The keys that make Net::Telnet open a connection in its constructor.
    my %removed_keys;
    # Parse the named arguments if there's any, but only those we care about.
    if (@_ > 1)
    {
        my %args = @_;
        foreach (keys %args)
        {
            # M-multiline regular expressions? W-what is this sorcery?
            if (/^-? # Match keys starting with '-', optionally.
                ( # Match either keys that begin with 'packet_' and
                    packet_(
                        # are one of the following,
                        mac|username|password|content|base64|instance|wait_timeout|delay|send_mode
                    )|
                    # Or keys that do not start with 'packet_' and are one of the following.
                    host|fhopen
                )$
                /xi)
            {
                # If we matched 'packet_*' (aka: if the second group of the regexp is defined),
                # then the target variable is $packetinfo. Otherwise, it's %removed_keys.
                my $target = defined $2 ? \%packetinfo : \%removed_keys;
                $target->{lc ($2 || $1)} = $args{$_}; # Assign the matched option to the hash.
                # Delete the key, either because Net::Telnet croaks if unknown keys are detected
                # (when dealing with 'packet_*'), or because they are problematic. (see the
                # definition of %removed_keys)
                delete $args{$_};
            }
            # Match boolean settings not related to packets and Net::Telnet stuff.
            elsif (/^-?(netgear_defaults|exit_on_destroy)$/i)
            {
                $settings->{lc $1} = !!$args{$_};
                delete $args{$_};
            }
        }
        # Process the packet information given by the user.
        # What? The user has given us a ::Packet instance? Jackpot!
        if (exists $packetinfo{instance})
        {
            Carp::croak "ERROR: packet_instance must be a Net::Telnet::Netgear::Packet instance"
                unless defined Scalar::Util::blessed ($packetinfo{instance})
                and    $packetinfo{instance}->isa ("Net::Telnet::Netgear::Packet");
            $packet = $packetinfo{instance};
        }
        # If the user provided a MAC address...
        elsif (exists $packetinfo{mac})
        {
            # Pass the entire %packetinfo hash to Net::Telnet::Netgear::Packet->new. This allows to
            # avoid redundant stuff (mac => $packetinfo{mac}, brr) and unnecessary checks.
            $packet = Net::Telnet::Netgear::Packet->new (%packetinfo);
        }
        elsif (exists $packetinfo{content}) # The following two cases are self-explanatory
        {
            $packet = Net::Telnet::Netgear::Packet->from_string ($packetinfo{content});
        }
        elsif (exists $packetinfo{base64})
        {
            $packet = Net::Telnet::Netgear::Packet->from_base64 ($packetinfo{base64});
        }
        # What if the user did not supply a packet at all? Well, that means that the user does not
        # need this module, probably. Who cares? Just do our business.
        # Parse the packet send mode, if specified.
        if (exists $packetinfo{send_mode})
        {
            _sanitize_packet_send_mode ($packetinfo{send_mode}); # Croaks if it's invalid
            $settings->{packet_send_mode} = $packetinfo{send_mode};
        }
        @_ = %args; # Magic? Nope, Perl. (hint: an hash is an unsorted array)
    }
    # If there's a single argument, then it's the hostname. Save it for later.
    elsif (@_ == 1)
    {
        $removed_keys{host} = shift;
    }
    # If there are no arguments, we are all set.
    # Create ourselves. Isn't that touching? :')
    my $self = $class->SUPER::new (@_);
    # Configure Net::Telnet::Netgear, in a Net::Telnet-esque way. (see the source of
    # "new" in Net::Telnet to understand what I'm saying)
    *$self->{net_telnet_netgear} = {
        %$settings,
        packet  => defined $packet && $packet->can ("get_packet") ? $packet->get_packet : undef,
    };
    # Set packet_delay and packet_wait_timeout
    $self->packet_delay (defined $packetinfo{delay} ? $packetinfo{delay} : .3);
    $self->packet_wait_timeout ($packetinfo{wait_timeout} || 1);
    # Restore the keys we previously removed.
    if (exists $removed_keys{fhopen})
    {
        $self->fhopen ($removed_keys{fhopen}) || return;
    }
    elsif (exists $removed_keys{host})
    {
        $self->host ($removed_keys{host});
        $self->open || return;
    }
    # We are done.
    $self;
}

sub DESTROY
{
    my $self = shift;
    # Try to send the 'exit' command before being destroyed, to avoid ghost shells.
    # (Yes, this is an issue in Netgear routers.)
    $self->cmd (string => "exit", errmode => "return") if $self->exit_on_destroy;
}

sub open
{
    my $self = shift;
    # If this method is being called from this package and it has '-callparent' as the first arg,
    # then execute the implementation of the superclass. This is a work-around, because
    # unfortunately $self->SUPER::$method does not work. :(
    return $self->SUPER::open (splice @_, 1)
        if (caller)[0] eq __PACKAGE__ && @_ > 0 && $_[0] eq -callparent;
    # Call our magical method.
    _open_method ($self, "open", @_);
}

sub fhopen
{
    my $self = shift;
    # If this method is being called from this package and it has '-callparent' as the first arg,
    # then execute the implementation of the superclass. This is a work-around, because
    # unfortunately $self->SUPER::$method does not work. :(
    return $self->SUPER::fhopen (splice @_, 1)
        if (caller)[0] eq __PACKAGE__ && @_ > 0 && $_[0] eq -callparent;
    # Call our magical method.
    _open_method ($self, "fhopen", @_);
}

sub apply_netgear_defaults
{
    my $self = shift;
    # Prefer user-provided settings, if available.
    local %NETGEAR_DEFAULTS = (%NETGEAR_DEFAULTS, @_) if @_ > 1;
    foreach my $k (keys %NETGEAR_DEFAULTS)
    {
        $self->$k ($NETGEAR_DEFAULTS{$k}) if defined $NETGEAR_DEFAULTS{$k} and $self->can ($k);
    }
}

# Getters/setters.
sub exit_on_destroy
{
    _mutator (shift, name => "exit_on_destroy", new => shift, sanitizer => sub { !!$_ });
}

sub packet_delay
{
    _mutator (shift, name => "delay", new => shift, sanitizer => sub {
        _sanitize_numeric_val ("packet_delay")
    });
}

sub packet_send_mode
{
    _mutator (shift, name => "packet_send_mode", new => shift,
        sanitizer => \&_sanitize_packet_send_mode);
}

sub packet_wait_timeout
{
    _mutator (shift, name => "timeout", new => shift, sanitizer => sub {
        _sanitize_numeric_val ("packet_wait_timeout")
    });
}

sub packet
{
    _mutator (shift, name => "packet", new => shift);
}

# Internal methods.
# Handles getters and setters. Code partially taken from Net::Telnet.
# %conf = (
#     name        => "xxx", # The name of the mutator
#     new         => "yyy", # The new value. (may be undef)
#     sanitizer   => CODE   # A subroutine which returns a sanitized value of 'new'.
# )
sub _mutator
{
    my ($self, %conf) = @_;
    my $s    = *$self->{net_telnet_netgear};
    my $prev = $s->{$conf{name}};
    if (exists $conf{new} && defined $conf{new})
    {
        if (exists $conf{sanitizer})
        {
            local $_ = $conf{new};
            $conf{new} = $conf{sanitizer}->($conf{new}, $prev);
        }
        $s->{$conf{name}} = $conf{new};
    }
    $prev;
}

# Sanitizes numeric values.
sub _sanitize_numeric_val
{
    my $param = shift;
    Carp::croak "ERROR: $param must be a number"
        unless /^-?\d+(?:\.\d+)?$/;
    $_;
}

# Sanitizes the packet send mode.
sub _sanitize_packet_send_mode
{
    my $val = shift;
    Carp::croak "ERROR: unknown packet_send_mode (must be auto, tcp or udp)"
        unless grep { $_ eq $val } "auto", "tcp", "udp";
    $val;
}

# _can_read returns:
#  1 if we can read.
#  0 if we can't read (timeout reached).
# -1 if an error occurred.
sub _can_read
{
    my ($self, $timeout) = @_;
    # Check if warnings are enabled. (-nowarnings as the second parameter disables warnings)
    my $should_warn = @_ < 3 || $_[2] ne -nowarnings;
    # Get access to the internals of Net::Telnet.
    my $net_telnet = *$self->{net_telnet};
    # If select is supported...
    if ($net_telnet->{select_supported})
    {
        # Then use it!
        # The source code of Net::Telnet helped.
        my ($ready, $nfound);
        $nfound = select $ready = $net_telnet->{fdmask}, undef, undef, $timeout;
        # If $nfound is not defined or if it is less than 0, return -1 (error).
        # If it is greater than 0, return 1 (ok), otherwise 0 (timeout).
        return !defined $nfound || $nfound < 0 ? -1 : $nfound ? 1 : 0;
    }
    # select is not supported. :(
    # Unfortunately, there is no other solution. Win32 does not interrupt blocking syscalls
    # (like read and sysread) with alarm, so it's useless. Let the user know.
    else
    {
        # We have two options: die horribly and let the user know about his shitty OS, or
        # return a fake value which disables the TCP packets of this module.
        # Let the developer pick... (see $DIE_ON_SELECT_UNAVAILABLE)
        my $base_msg = $DIE_ON_SELECT_UNAVAILABLE ? "ERROR" : "WARNING";
        ($base_msg  .= <<ERROR_MSG) =~ s/^(\w*:?)\s+/$1/gm; # remove useless spaces
            : Unsupported platform detected (no select support).
            See the section 'THE MAGIC BEHIND TIMEOUTS' of the manual of Net::Telnet::Netgear.
ERROR_MSG
        return $self->error ($base_msg . "Stopped") if $DIE_ON_SELECT_UNAVAILABLE;
        !$DIE_ON_SELECT_UNAVAILABLE && $should_warn && warnings::enabled() && warnings::warn (
            $base_msg . "Disabling the capability of sending packets using TCP. Warned"
        );
        # NOTE: UDP packets will still work even if select is not available.
        return 1;
    }
}

# Sends the packet over UDP.
sub _udp_send_packet
{
    my $self = shift;
    my $s = *$self->{net_telnet_netgear};
    # We have to use IO::Socket::INET to do this, since (obviously) Net::Telnet does not
    # support UDP.
    my ($host, $port) = ($self->host, $self->port);
    my $sock = IO::Socket::INET->new (
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => "udp"
    ) || return $self->error ("Error while creating the UDP socket for $host:$port: $!\n");
    binmode $sock;
    $sock->send ($s->{packet})
        || return $self->error ("Can't send the packet to $host:$port (UDP): $!\n");
    close $sock;
    # Wait packet_delay seconds.
    select undef, undef, undef, $self->packet_delay;
}

# The internal function used to handle the *open calls.
sub _open_method
{
    my ($self, $method, @params) = @_;
    # Get access to our internals.
    my $s = *$self->{net_telnet_netgear};
    # Fix 'select_supported' for older versions of Net::Telnet.
    unless (exists *$self->{net_telnet}{select_supported})
    {
        # Taken from the source code of Net::Telnet 3.04, line 710 / 1671
        *$self->{net_telnet}{select_supported} = $method eq "open" ?
            1 :
            ($^O ne "MSWin32" || -S $self);
    }
    # Handle the different packet_send_mode conditions, but only when we have a packet.
    if (defined $s->{packet})
    {
        # If the packet send mode is "auto", then suppress connection errors, because we need to
        # check whether the connection is successful or not later.
        if ($self->packet_send_mode eq "auto")
        {
            push @params, errmode => sub {};
        }
        # Otherwise, if the connection mode is "udp", then we pre-send the packet over UDP before
        # connecting.
        elsif ($self->packet_send_mode eq "udp")
        {
            # We can't pre-send the packet if the 'host' and 'port' variables are not defined
            # correctly, so we fix that.
            if (@params == 1)
            {
                $self->host (shift @params);
            }
            elsif (@params >= 2)
            {
                my %args = @params;
                foreach (keys %args)
                {
                    if (/^-?(host|port)$/i)
                    {
                        # Use the matched option as a method name.
                        my $method = lc $1;
                        $self->$method ($args{$_});
                        # Delete the argument to avoid redundancy.
                        delete $args{$_};
                    }
                }
                @params = %args; # Magic? Nope, Perl. (hint: an hash is an unsorted array)
            }
            _udp_send_packet ($self);
        }
    }
    # Use unshift to propagate '-callparent' to every other call. This is important!!!
    unshift @params, -callparent;
    # Call the original method and get the return value.
    # This does not cause infinite recursion thanks to '-callparent' and the magical check.
    my $v = $self->$method (@params);
    # No packet, no party.
    return $v unless defined $s->{packet};
    if ($v && $self->packet_send_mode ne "udp")
    {
        # It looks like the open was successful. Time to do something useful.
        # Check if we can read within the timeout.
        my $can_read = _can_read ($self, $s->{timeout});
        if ($can_read == 0) # Timeout
        {
            # We can't read, so this (usually) means that the router is expecting a Telnet packet.
            # Send it.
            $self->put (string => $s->{packet}, binmode => 1, telnetmode => 0);
            $self->close;
            # Wait for a bit. (it's Netgear's fault)
            select undef, undef, undef, $self->packet_delay;
            # Re-open. If we can't read again, then I have bad news.
            return $self->error ("Can't reopen the socket after sending the Telnet packet: " .
                                 $self->errmsg . "\n") unless $self->$method (@params);
            return $self->error ("Can't read from the socket after sending the Telnet packet.\n")
                if _can_read ($self, $s->{timeout}, -nowarnings) != 1;
        }
        elsif ($can_read == -1) # Error
        {
            return $self->error (
                "Read error while trying to determine if the Telnet packet is necessary.\n"
            );
        } # $can_read == 1 -> OK, but we don't care if it is
    }
    elsif ($s->{packet_send_mode} eq "auto")
    {
        # The connection to the Telnet server failed. But wait! Netgear changed the Telnet enabling
        # system. Now the packet has to be sent on UDP and by default the Telnet daemon is not even
        # running, so this could be the case. Try to send the packet over UDP.
        _udp_send_packet ($self);
        # Now, open the connection over TCP and see if everything is OK.
        $v = $self->$method (@params);
    }
    # Load the Netgear defaults, if requested.
    $self->apply_netgear_defaults if $v && $s->{netgear_defaults};
    $v;
}

1;

=encoding utf8

=head1 NAME

Net::Telnet::Netgear - Generate and send Netgear Telnet-enable packets through Net::Telnet

=head1 SYNOPSIS

    use Net::Telnet::Netgear;
    my $telnet = Net::Telnet::Netgear->new (
        # Standard Net::Telnet parameters are allowed
        host             => 'example.com',
        packet_mac       => 'AA:BB:CC:DD:EE:FF', # or AABBCCDDEEFF
        packet_username  => 'admin',
        packet_password  => 'hunter2',
        netgear_defaults => 1
    );
    # The magic is done transparently: the packet has already been sent,
    # if necessary, and the standard Net::Telnet API can now be used.
    my @lines = $telnet->cmd ('whoami');

    use Net::Telnet::Netgear::Packet;
    # Manually create a packet.
    my $packet = Net::Telnet::Netgear::Packet->new (mac => '...');
    say length $packet->get_packet; # or whatever you want
    $packet = Net::Telnet::Netgear::Packet->from_base64 ('...');
    $packet = Net::Telnet::Netgear::Packet->from_string ('...');

=head1 DESCRIPTION

This module allows to programmatically generate and send magic Telnet-enabling packets for
Netgear routers with a locked Telnet interface. The packet can either be user-provided or it can
be automatically generated given the username, password and MAC address of the router. Also, this
module is capable of sending packets using TCP or UDP (the latter is used on new firmwares), and
can automatically pick the right protocol to use, making it compatible with old and new firmwares
without any additional configuration.

The work on the Telnet protocol is done by L<Net::Telnet>, which is subclassed by this module.
In fact, it's possible to use the entire L<Net::Telnet> API and configuration parameters.

=head1 METHODS

L<Net::Telnet::Netgear> inherits all methods from L<Net::Telnet> and implements the following new
ones.

=head2 new

    my $instance = Net::Telnet::Netgear->new (%options);

Creates a new C<Net::Telnet::Netgear> instance. Returns C<undef> on failure.

C<%options> can contain any of the options valid with the constructor of L<Net::Telnet>,
with the addition of:

=over 4

=item * C<< packet_mac => 'AA:BB:CC:DD:EE:FF' >>

The MAC address of the router where the packet will be sent to. Each non-hexadecimal character
(like colons) will be removed.

=item * C<< packet_username => 'admin' >>

The username that will be put in the packet. Defaults to C<Gearguy> for compatibility reasons.
With new firmwares, the username C<admin> should be used.

Has no effect if C<packet_mac> is not specified.

=item * C<< packet_password => 'password' >>

The password that will be put in the packet. Defaults to C<Geardog> for compatibility reasons.
With new firmwares, the password of the router interface should be used.

Has no effect if C<packet_mac> is not specified.

=item * C<< packet_content => 'string' >>

The content of the packet to be sent, as a string.

Only makes sense if the packet is not defined elsewhere.

=item * C<< packet_base64 => 'b64_string' >>

The content of the packet to be sent, as a Base64 encoded string.

Only makes sense if the packet is not defined elsewhere.

=item * C<< packet_instance => ... >>

A subclass of L<Net::Telnet::Netgear::Packet> to be used as the packet.

Only makes sense if the packet is not defined elsewhere.

B<NOTE:> Packets generated with L<Net::Telnet::Netgear::Packet/"new">,
L<Net::Telnet::Netgear::Packet/"from_string"> and L<Net::Telnet::Netgear::Packet/"from_base64">
can be used too.

=item * C<< packet_delay => .50 >>

The amount of time, in seconds, to wait after sending the packet.
In pseudo-code: C<send_packet(); wait(packet_delay); connect()>

Defaults to C<.3> seconds, or 300 milliseconds. Can be C<0>.

=item * C<< packet_wait_timeout => .75 >>

The amount of time, in seconds, to wait for a response from the server before sending the packet.
In pseudo-code: C<connect(); if !can_read(in packet_wait_timeout seconds) then send_packet()>

Only effective when the packet is sent using TCP. Defaults to C<1> second.

=item * C<< packet_send_mode => 'auto|tcp|udp' >>

Determines how to send the packet. See L</"packet_send_mode"> below.

Defaults to C<auto>.

=item * C<< netgear_defaults => 0|1 >>

If enabled, the default values defined in the hash C<%Net::Telnet::Netgear::NETGEAR_DEFAULTS> are
applied once the connection is established. See L</"DEFAULT VALUES USING %NETGEAR_DEFAULTS">.

Defaults to C<0>.

=item * C<< exit_on_destroy => 0|1 >>

If enabled, the C<exit> shell command is sent before the object is destroyed. This is useful to
avoid ghost processes when closing a Telnet connection without killing the shell first.

Defaults to C<0>.

=back

=head2 apply_netgear_defaults

    $instance->apply_netgear_defaults;
    $instance->apply_netgear_defaults (
        prompt => '/rxp/',
        cmd_remove_mode => 0
    );
    %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (exit_on_destroy => 1);
    $instance->apply_netgear_defaults;

Applies the values specified in the hash C<%Net::Telnet::Netgear::NETGEAR_DEFAULTS>. If any
argument is specified, it is temporarily added to the hash.

See L</"DEFAULT VALUES USING %NETGEAR_DEFAULTS">.

=head2 exit_on_destroy

    my $current_value = $instance->exit_on_destroy;
    # Set exit_on_destroy to 1
    my $old_value = $instance->exit_on_destroy (1);

Gets or sets the value of the boolean flag C<exit_on_destroy>, which causes the module to send
the C<exit> shell command before being destroyed. This is to avoid ghost processes when closing
a Telnet connection without killing the shell first.

=head2 packet

    my $current_value = $instance->packet;
    # Set the content of the packet to '...'
    my $old_value = $instance->packet ('...');

Gets or sets the value of the packet B<as a string>. This is basically equivalent to the
C<packet_content> constructor parameter.

Note that objects cannot be used - you have to call L<Net::Telnet::Netgear::Packet/"get_packet">
before passing the value to this method.

=head2 packet_delay

    my $current_value = $instance->packet_delay;
    # Set packet_delay to .75 seconds
    my $old_value = $instance->packet_delay (.75);

Gets or sets the amount of time, in seconds, to wait after sending the packet.

=head2 packet_send_mode

    my $current_value = $instance->packet_send_mode;
    # Set packet_send_mode to 'udp'
    my $old_value = $instance->packet_send_mode ('udp');

Gets or sets the protocol used to send the packet, between C<tcp>, C<udp> and C<auto>.

If it is C<auto>, then the module will try to guess the correct protocol to use. More specifically,
if the initial C<open> performed on the specified C<host> and C<port> fails, the packet is sent
using UDP (and then the connection is reopened). Otherwise, if the C<open> succeeds but it's
impossible to read within the L</"packet_wait_timeout">, the packet is sent using TCP.

If it is C<tcp>, the packet is sent using TCP.

If it is C<udp>, the packet is sent using UDP. Note that in this case the packet is always sent
before an C<open> call.

B<NOTE:> Generally, specifying the protocol instead of using C<auto> is faster, especially when
the packet has to be sent using UDP (due to the additional connection that has to be made).

=head2 packet_wait_timeout

    my $current_value = $instance->packet_wait_timeout;
    # Set packet_wait_timeout to 1.25
    my $old_value = $instance->packet_wait_timeout (1.25);

Gets or sets the the amount of time, in seconds, to wait for a response from the server before
sending the packet.

Only effective when the packet is sent using TCP.

=head1 IMPLEMENTATION DETAILS

When you open a connection with L<Net::Telnet::Netgear> (either with the C<(fh)open> methods
inherited from L<Net::Telnet> or by specifying the C<host> constructor parameter), the following
actions are performed depending on the value of L</"packet_send_mode">.

B<NOTE:> when C<fhopen> is used, "socket" refers to the filehandle.

=over 4

=item "auto"

This is the default. First, L<Net::Telnet> tries to open the socket. If it succeeds,
then it's assumed that the server may want a TCP packet. To check if the server actually needs
it, a L<perlfunc/"select"> call is performed on the socket to determine if data is available
to read. If data is available, then nothing is done. Otherwise, the packet is sent using TCP and
then the socket is re-opened.

If the initial C<open> didn't succeed, then the server is not listening on the port. It's assumed
that the server wants an UDP packet, and it is immediately sent. The socket is re-opened, and if
it fails again the error is propagated.

=item "tcp"

The actions specified in the first case apply, except that if the initial C<open> goes wrong the
error is immediately propagated.

=item "udp"

The packet is immediately sent before the C<open> performed by L<Net::Telnet>. If it fails, the
error is immediately propagated.

=back

=head1 DEFAULT VALUES USING %NETGEAR_DEFAULTS

As an added feature, it's possible to enable a set of options suitable for Netgear routers.
This is possible with the hash C<%Net::Telnet::Netgear::NETGEAR_DEFAULTS>, which contains a list
of methods to be called on the current instance along with their parameters. This is done by the
method L</"apply_netgear_defaults">.

The current version specifies the following list of default values:

    method              value
    -----------------   -----------
    cmd_remove_mode     1
    exit_on_destroy     1
    prompt              '/.* # $/'
    waitfor             '/.* # $/'

It is possible to edit this list either by interacting directly with it:

    $Net::Telnet::Netgear::NETGEAR_DEFAULTS{some_option} = 'some_value';
    delete $Net::Telnet::Netgear::NETGEAR_DEFAULTS{some_option};
    %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (
        option1 => 'value1',
        option2 => 'value2'
    );

Or you can supply additional parameters to L</"apply_netgear_defaults">, which will be temporarily
added to the list. Note that user-specified values have priority over the ones in the hash, and
if you specify the value of an option as C<undef>, it won't be set at all.

    # cmd_remove_mode is set to 0 instead of 1, along with all the other
    # default values
    $instance->apply_netgear_defaults (cmd_remove_mode => 0);
    # do not set cmd_remove_mode at all, but apply every other default
    $instance->apply_netgear_defaults (cmd_remove_mode => undef);
    # the standard list of default values is applied plus 'some_option'
    $instance->apply_netgear_defaults (some_option => 'some_value');
    # equivalent to:
    {
        local %Net::Telnet::Netgear::NETGEAR_DEFAULTS = (
            %Net::Telnet::Netgear::NETGEAR_DEFAULTS,
            some_option => 'some_value'
        );
        $instance->apply_netgear_defaults;
    }

=head1 THE MAGIC BEHIND TIMEOUTS

C<Net::Telnet::Netgear> uses a timeout to determine if it should send the packet (using TCP).
But what's the magic behind this mysterious decimal number?

Timeouts, under normal conditions, are implemented using the L<perlfunc/"select"> function (which
calls the L<select(2)> syscall). This magic function is awesome, and it works beautifully.

It would be great if the story ended here, but happy endings are pretty rare in real life.

C<select> works basically everywhere when dealing with network sockets, but it doesn't work on
certain systems when dealing with generic filehandles (I<Win32, I'm looking at you!>).
L<Net::Telnet> can make Telnet work on arbitrary filehandles (thanks to L<Net::Telnet/"fhopen">),
but that means that C<select> may not be always available. This is a problem, and you can specify
what to do in this case with the boolean variable
C<$Net::Telnet::Netgear::DIE_ON_SELECT_UNAVAILABLE>.

If this variable is false (the default), then if C<select> is not available the module will simply
never send packets using TCP and emit a warning. This may not be always desiderable.

If this variable is true, then if C<select> is unavailable the module will call
C<< Net::Telnet->error >> which, when C<errmode> is the default, stops the execution of the script.

B<NOTE:> If L</"packet_send_mode"> is set to C<udp>, then C<select> is never called, thus
C<$Net::Telnet::Netgear::DIE_ON_SELECT_UNAVAILABLE> won't have any effect even if C<select> is
unavailable.

=head1 CAVEATS

An C<open> call may require serious amounts of time, depending on the L</"packet_send_mode"> and
L</"packet_wait_timeout">.
Particularly, if no packet has to be sent, then C<tcp> or C<auto> are the fastest. Otherwise,
C<udp> is the fastest (because there are no timeouts, and the packet is immediately sent).
C<auto> is the slowest when the router requires the packet on UDP, because a connection is
attempted on the TCP port, while it has the same speed of C<tcp> when the packet is expected on
TCP.

=head1 SEE ALSO

L<Net::Telnet>, L<Net::Telnet::Netgear::Packet>,
L<http://wiki.openwrt.org/toh/netgear/telnet.console>,
L<https://github.com/Robertof/perl-net-telnet-netgear>

=head1 AUTHOR

Roberto Frenna (robertof AT cpan DOT org)

=head1 THANKS

Thanks to L<Derreck "insanid"|https://github.com/insanid> for the precious contribution to
the OpenWRT wiki page, and for helping me to discovery the mistery behind the "strange" packets
generated with long passwords.

Thanks to L<the authors of Mojolicious|Mojolicious> for inspiration about the license and the
documentation.

=head1 LICENSE

Copyright (C) 2014-2015, Roberto Frenna.

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=cut
