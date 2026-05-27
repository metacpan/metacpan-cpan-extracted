#!/usr/bin/false
# ABSTRACT: NIS Servers option (code 27) — list of IPv6 addresses
# PODNAME: Net::DHCPv6::Option::NisServers
package Net::DHCPv6::Option::NisServers;
$Net::DHCPv6::Option::NisServers::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    my $addrs = $args{servers} // $args{addresses} // [];
    $addrs      = [$addrs] unless is_plain_arrayref( $addrs );
    $args{code} = $OPTION_NIS_SERVERS;
    $args{data} = join( '', @$addrs );
    my $self = $class->SUPER::new( %args );
    $self->{servers} = $addrs;
    bless $self, $class;
}

sub servers { shift->{servers} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated NisServers option' )
        if CORE::length( $data ) % 16 != 0;
    my @addrs;
    for ( my $i = 0 ; $i < CORE::length( $data ) ; $i += 16 ) {
        push @addrs, substr( $data, $i, 16 );
    }
    return $class->new( servers => \@addrs );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_NIS_SERVERS} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::NisServers - NIS Servers option (code 27) — list of IPv6 addresses

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::NisServers;
  my $opt = Net::DHCPv6::Option::NisServers->new(
      servers => [ $ipv6_bytes ],
  );

=head1 DESCRIPTION

Carries a list of IPv6 addresses of NIS servers available to
the client.  See RFC 3898.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<servers> (arrayref of 16-byte IPv6 addresses).

=head2 servers

Returns an arrayref of 16-byte IPv6 addresses.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
