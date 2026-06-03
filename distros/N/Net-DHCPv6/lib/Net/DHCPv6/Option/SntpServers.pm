#!/bin/false
# ABSTRACT: SNTP Servers option (code 31) -- list of IPv6 addresses per RFC 4075
# PODNAME: Net::DHCPv6::Option::SntpServers
use strictures 2;

package Net::DHCPv6::Option::SntpServers;
$Net::DHCPv6::Option::SntpServers::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $IPV6_ADDR_LEN $OPTION_SNTP_SERVERS
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use Ref::Util qw( is_plain_arrayref );
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    my $addresses = $class->_pick_addrs( \%args, 'servers' );
    if ( !defined $addresses && $args{addresses} ) {
        my $list = is_plain_arrayref( $args{addresses} ) ? $args{addresses} : [ $args{addresses} ];
        $addresses = [ map { $class->_resolve_ipv6( $_ ) } @{$list} ];
    }
    $addresses //= [];
    $args{code} = $OPTION_SNTP_SERVERS;
    $args{data} = join( $EMPTY, @{$addresses} );
    my $self = $class->SUPER::new( %args );
    $self->{servers} = $addresses;
    return bless $self, $class;
}

sub servers_raw { return shift->{servers} }

sub servers {
    my $self = shift;
    return [ map { $self->_format_ipv6( $_ ) } @{ $self->{servers} } ];
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated SntpServers option' )
        if CORE::length( $payload ) % $IPV6_ADDR_LEN != 0;
    my @addrs;
    while ( CORE::length( $payload ) ) {
        push @addrs, substr( $payload, 0, $IPV6_ADDR_LEN, q() );
    }
    return $class->new( servers_raw => \@addrs );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SNTP_SERVERS} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::SntpServers - SNTP Servers option (code 31) -- list of IPv6 addresses per RFC 4075

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # Text form (auto-resolved to wire bytes)
  my $opt = Net::DHCPv6::Option::SntpServers->new(
      servers => [ '2001:db8::1', '2001:db8::2' ],
  );
  print $opt->servers->[0];           # '2001:db8::1'
  print $opt->servers_raw->[0];       # 16-byte wire-format bytes

  # Raw bytes
  use Socket qw(inet_pton AF_INET6);
  my $opt2 = Net::DHCPv6::Option::SntpServers->new(
      servers_raw => [ inet_pton( AF_INET6, '2001:db8::1' ) ],
  );

=head1 DESCRIPTION

Carries a list of IPv6 addresses of SNTP servers available to
the client.  See RFC 4075 (code 31).

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<servers> (arrayref of IPv6 text addresses) or
C<servers_raw> (arrayref of 16-byte IPv6 addresses).

=head2 servers

Returns an arrayref of IPv6 text addresses.

=head2 servers_raw

Returns an arrayref of 16-byte wire-format addresses.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
