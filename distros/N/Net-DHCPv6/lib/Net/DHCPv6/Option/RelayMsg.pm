#!/usr/bin/false
# ABSTRACT: Relay Message option (code 9) — encapsulated relay message
# PODNAME: Net::DHCPv6::Option::RelayMsg
package Net::DHCPv6::Option::RelayMsg;
$Net::DHCPv6::Option::RelayMsg::VERSION = '0.001';
use strictures 2;
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_RELAY_MSG;
    $args{data} = $args{data} // ( $args{message} // '' );
    my $self = $class->SUPER::new( %args );
    $self->{message} = $args{data};
    bless $self, $class;
}

sub message { shift->{message} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    return $class->new( message => $data );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_RELAY_MSG} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::RelayMsg - Relay Message option (code 9) — encapsulated relay message

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::RelayMsg;
  my $opt = Net::DHCPv6::Option::RelayMsg->new(message => $bytes);

=head1 DESCRIPTION

Carries an encapsulated DHCPv6 message between relay agents and
servers.  See RFC 8415 §21.9.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<message> (raw bytes, defaults to empty).

=head2 message

Returns the encapsulated message bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
