#!/bin/false
# ABSTRACT: NTP Server option (code 56) -- sub-options for NTP configuration per RFC 5908
# PODNAME: Net::DHCPv6::Option::NtpServer
use strictures 2;

package Net::DHCPv6::Option::NtpServer;
$Net::DHCPv6::Option::NtpServer::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY = q();

my %SUBOPT_DECODE = (
    1 => sub { my ( $v ) = @_; return { subopt => 1, type => 'address', value => $v } },
    2 => sub { my ( $v ) = @_; return { subopt => 2, type => 'fqdn',    value => $v } },
    3 => sub { my ( $v ) = @_; return { subopt => 3, type => 'domain',  value => $v } },
);

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_NTP_SERVER;
    my $entries = $args{entries} // [];
    $args{data} =
        join( $EMPTY, map { pack( 'n n', $_->{subopt}, CORE::length( $_->{value} ) ) . $_->{value} } @{$entries} );
    my $self = $class->SUPER::new( %args );
    $self->{entries} = $entries;
    return bless $self, $class;
}

sub entries { return shift->{entries} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my @entries;
    my $len = CORE::length( $payload );
    my $off = 0;
    while ( $off + 4 <= $len ) {
        my $sc   = unpack( 'n', substr( $payload, $off,     2 ) );
        my $slen = unpack( 'n', substr( $payload, $off + 2, 2 ) );
        $off += 4;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated NtpServer sub-option' )
            if $off + $slen > $len;
        my $sv = substr( $payload, $off, $slen );
        $off += $slen;
        my $decoder = $SUBOPT_DECODE{$sc};
        if ( $decoder ) {
            push @entries, $decoder->( $sv );
        }
        else {
            push @entries, { subopt => $sc, value => $sv };
        }
    }
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated NtpServer sub-option header' )
        if $off != $len;
    return $class->new( entries => \@entries );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_NTP_SERVER} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::NtpServer - NTP Server option (code 56) -- sub-options for NTP configuration per RFC 5908

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $raw   = $dhcpv6_msg->options->get_option( 56 );
  for my $e ( @{ $raw->entries } ) {
      say "$e->{type}: $e->{value}";
  }

=head1 DESCRIPTION

Carries NTP server configuration as a set of sub-options per
RFC 5908.  Sub-option codes:

  1  NTP Sub-option Address (16-byte IPv6 address)
  2  NTP Sub-option FQDN (domain name)
  3  NTP Sub-option Domain (domain name)

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<entries> (arrayref of hashrefs with
C<subopt> and C<value> keys).

=head2 entries

Returns the arrayref of sub-option hashrefs.  Each known sub-option
also includes a C<type> key (one of C<address>, C<fqdn>, C<domain>).

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>,
RFC 5908.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
