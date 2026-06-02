#!/bin/false
# ABSTRACT: Reconfigure Message option (code 19) -- 1-byte msg-type
# PODNAME: Net::DHCPv6::Option::ReconfMsg
use strictures 2;

package Net::DHCPv6::Option::ReconfMsg;
$Net::DHCPv6::Option::ReconfMsg::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ReconfMsg requires msg_type' unless defined $args{msg_type};
    $args{code} = $OPTION_RECONF_MSG;
    $args{data} = pack( 'C', $args{msg_type} );
    my $self = $class->SUPER::new( %args );
    $self->{msg_type} = $args{msg_type};
    return bless $self, $class;
}

sub msg_type { return shift->{msg_type} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated ReconfMsg option' )
        if CORE::length( $payload ) < 1;
    my $type = unpack( 'C', $payload );
    return $class->new( msg_type => $type );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_RECONF_MSG} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ReconfMsg - Reconfigure Message option (code 19) -- 1-byte msg-type

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ReconfMsg;
  use Net::DHCPv6::Constants qw($RENEW);

  my $opt = Net::DHCPv6::Option::ReconfMsg->new(
      msg_type => $RENEW,
  );

=head1 DESCRIPTION

Carries the message type of a Reconfigure message.  See RFC 8415 E<167>21.21.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<msg_type> (0-255).

=head2 msg_type

Returns the message type value.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
