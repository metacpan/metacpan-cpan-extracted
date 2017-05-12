package Net::Telnet::Netgear::Packet::Native;
use strict;
use warnings;
use parent "Net::Telnet::Netgear::Packet";
use Carp;
use Crypt::ECB ();
use Digest::MD5;

our @CARP_NOT = qw ( Net::Telnet::Netgear::Packet );

sub new
{
    my ($self, %opts) = @_;
    Carp::croak "Missing required parameter 'mac'"
        unless exists $opts{mac};
    $opts{mac} =~ s/\W//g;
    # WARNING: "Gearguy" and "Geardog" are no longer valid since the new firmwares of Netgear
    # routers. You need to specify the username/password combination you use to login in the
    # control panel. (default: admin/password)
    $opts{username} ||= "Gearguy";
    $opts{password} ||= "Geardog";
    Carp::croak "The MAC address and the username have to be shorter than 16 characters"
        unless length $opts{mac} < 16
        and    length $opts{username} < 16;
    # Increase the maximum password length to 33 characters.
    # See the discussion here: https://github.com/insanid/netgear-telenetenable/commit/445c972
    # Long story short: the original packet structure specifies 5 fields: username, password, mac,
    # signature, reserved. Each field excluding 'reserved' is 0x10 (16) characters. However,
    # it looks like the length of the 'password' field can be increased up to 33 characters, which
    # is the maximum length allowed for the password by the Netgear interface. The analysis of what
    # happens is in the GitHub link written before.
    Carp::croak "The password must have a maximum length of 33 characters."
        unless length $opts{password} <= 33;
    bless \%opts, $self;
}

# Generates the packet. Here's some documentation:
# http://wiki.openwrt.org/toh/netgear/telnet.console
# Special thanks to insanid@github, he's a nice guy.
sub get_packet
{
    my $self = shift;
    my ($mac, $usr, $pwd) = (
        _left_justify ($self->{mac},      0x10, "\x00"),
        _left_justify ($self->{username}, 0x10, "\x00"),
        _left_justify ($self->{password}, 0x21, "\x00")
    );
    my $text    = _left_justify ($mac . $usr . $pwd, 0x70, "\x00");
    my $payload = _swap_bytes (
        _left_justify (Digest::MD5::md5 ($text) . $text, 0x80, "\x00")
    );
    my $cipher = Crypt::ECB->new;
    # Compatibility note: Crypt::ECB, since version 2.00, drops the constant `PADDING_NONE` and
    # replaces its usage with a string.
    $cipher->padding (Crypt::ECB->can ("PADDING_NONE") ? Crypt::ECB->PADDING_NONE : "none");
    # The method `cipher` now dies when something goes wrong instead of returning a falsey value.
    # However, in this case, the old implementation works fine.
    $cipher->cipher ("Blowfish")
        || die "Blowfish not available: ", $cipher->errstring;
    $cipher->key ("AMBIT_TELNET_ENABLE+" . $self->{password});
    _swap_bytes ($cipher->encrypt ($payload));
}

# https://goo.gl/qYA1u5
# TL;DR: The Blowfish implementation of Netgear expects data in big endian
# order, but we are using the little endian order. This fixes the problem.
# Also, from perldoc -f pack:
# - V  An unsigned long (32-bit) in "VAX" (little-endian) order.
# - N  An unsigned long (32-bit) in "network" (big-endian) order.
sub _swap_bytes
{
    pack 'V*', unpack 'N*', shift;
}

# See https://docs.python.org/2/library/string.html#string.ljust
# Left-justifies $str to $length characters, filling with $filler if necessary.
# Example:
# _left_justify 'meow', 6, 'A' -> 'meowAA'
sub _left_justify
{
    my ($str, $length, $filler) = @_;
    $filler ||= " ";
    my $i = length $str;
    return $str if $i >= $length;
    $str .= $filler while ($i++ < $length);
    $str;
}

1;
