#!/bin/false
# ABSTRACT: Interface-ID option (code 18) -- opaque interface identifier
# PODNAME: Net::DHCPv6::Option::InterfaceId
use strictures 2;

package Net::DHCPv6::Option::InterfaceId;
$Net::DHCPv6::Option::InterfaceId::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_INTERFACE_ID
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_INTERFACE_ID;
    $args{data} = $args{data} // ( $args{interface_id} // $EMPTY );
    return $class->SUPER::new( %args );
}

sub interface_id { return shift->{data} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new( interface_id => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_INTERFACE_ID} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::InterfaceId - Interface-ID option (code 18) -- opaque interface identifier

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::InterfaceId;
  my $opt = Net::DHCPv6::Option::InterfaceId->new(interface_id => $bytes);

=head1 DESCRIPTION

Opaque identifier used by relay agents to identify the interface on
which the client message was received.  See RFC 8415 E<167>21.18.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<interface_id> (raw bytes, defaults to empty).

=head2 interface_id

Returns the opaque interface identifier bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
