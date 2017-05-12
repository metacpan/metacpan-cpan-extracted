use strict;
use warnings FATAL => 'all';
use 5.014;
package NetObj::IPv4Address;
$NetObj::IPv4Address::VERSION = '1.0';
# ABSTRACT: represent a IPv4 address

use Moo;
use Carp;
use List::MoreUtils qw( all );

sub _to_binary {
    my ($ipaddr) = @_;

    my @octets = split(qr{\.}, $ipaddr);
    return unless @octets == 4;
    return unless all {
        ($_ =~ m{\A \d+ \Z}xms) and ($_ >=0) and ($_ <= 255);
    } @octets;

    return pack('CCCC', @octets);
}

use namespace::clean;

sub is_valid {
    my ($ipaddr) = @_;
    croak 'NetObj::IPv4Adress::is_valid is a class method only'
    if ref($ipaddr) eq __PACKAGE__;

    return !! _to_binary($ipaddr);
}

has binary => (
    is => 'ro',
);

sub BUILDARGS {
    my ($class, $ip, @args) = @_;
    croak 'no IPv4 address given' unless defined($ip);
    croak 'too many arguments in constructor for ' . __PACKAGE__ if @args;

    return { binary => $ip->binary() } if ref($ip) eq __PACKAGE__;

    $ip = _to_binary($ip) unless length($ip) == 4;
    croak 'invalid IPv4 address' unless $ip;

    return { binary => $ip };
}

sub to_string {
    my ($self) = @_;

    return join('.', unpack('CCCC', $self->binary()));
}

use overload q("") => sub {shift->to_string};

use overload q(<=>) => sub {
    my ($a, $b) = @_;
    return ($a->binary() cmp NetObj::IPv4Address->new($b)->binary());
};

use overload q(cmp) => sub { my ($a, $b) = @_; return $a <=> $b; };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetObj::IPv4Address - represent a IPv4 address

=head1 VERSION

version 1.0

=head1 SYNOPSIS

  use NetObj::IPv4Address;

  # constructor
  my $ip1 = NetObj::IPv4Address->new('127.0.0.1');

  # convert to string
  $ip1->to_string(); # "127.0.0.1"
  "$ip1" ; # "127.0.0.1" by implicit stringification

  # comparison, numerically and stringwise
  my $ip2 = NetObj::IPv4Address->new('192.168.0.1');
  $ip1 == $ip1; # true
  $ip1 == $ip2; # false
  $ip1 != $ip2; # true
  $ip1 eq $ip1; # true
  $ip1 eq $ip2; # false
  $ip1 ne $ip2; # true

  # test for validity
  NetObj::IPv4Address::is_valid('127.0.0.1'); # true
  NetObj::IPv4Address::is_valid('1.2.3.4.5'); # false

  # construct from raw binary IPv4 address (4 bytes)
  my $ip2 = NetObj::IPv4Address->new("\x7f\x00\x00\x01"); # 127.0.0.1

=head1 DESCRIPTION

NetObj::IPv4Address represents IPv4 addresses.

NetObj::IPv4Address is implemented as a Moose style object class (using Moo).

=head1 METHODS

=head2 is_valid

The class method C<NetObj::IPv4Address::is_valid> tests for the validity of a
IPv4 address represented by a string.  It does not throw an exception but
returns false for an invalid and true for a valid IPv4 address.

If called on an object it does throw an exception.

=head2 new

The constructor expects exactly one argument representing an IPv4 address as a
string in the usual form of 4 decimal numbers between 0 and 255 separated by
dots.

Raw 4 byte IPv4 addresses are supported.

It throws an exception for invalid IPv4 addresses.

=head2 to_string

The method C<to_string> returns the canonical string representation of the IPv4
address as dotted decimal octets.

Implicit stringification in string context is supported.

=head2 binary

The C<binary> method returns the raw 4 bytes of the IPv4 address.

=for Pod::Coverage BUILDARGS

=head1 AUTHOR

Elmar S. Heeb <elmar@heebs.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Elmar S. Heeb.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
