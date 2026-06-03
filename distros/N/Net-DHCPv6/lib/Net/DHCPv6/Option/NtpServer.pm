#!/bin/false
# ABSTRACT: NTP Server option (code 56) -- sub-options for NTP configuration per RFC 5908
# PODNAME: Net::DHCPv6::Option::NtpServer
use strictures 2;

package Net::DHCPv6::Option::NtpServer;
$Net::DHCPv6::Option::NtpServer::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_NTP_SERVER
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY              = q();
my $NTP_SUBOPT_ADDR    = 1;
my $NTP_SUBOPT_DOMAIN  = 3;     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $NTP_SUBOPT_FQDN    = 2;
my $NTP_SUBOPT_HDR_LEN = 4;     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

my %SUBOPT_DECODE = (
    $NTP_SUBOPT_ADDR => sub {
        my ( $v ) = @_;
        return { subopt => $NTP_SUBOPT_ADDR, type => 'address', value => $v };
    },
    $NTP_SUBOPT_FQDN => sub {
        my ( $v ) = @_;
        return { subopt => $NTP_SUBOPT_FQDN, type => 'fqdn', value => $v };
    },
    $NTP_SUBOPT_DOMAIN => sub {
        my ( $v ) = @_;
        return { subopt => $NTP_SUBOPT_DOMAIN, type => 'domain', value => $v };
    },
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
    my @decoded;
    my $len = CORE::length( $payload );
    my $off = 0;
    while ( $off + $NTP_SUBOPT_HDR_LEN <= $len ) {
        my $sc   = unpack( 'n', substr( $payload, $off,     2 ) );
        my $slen = unpack( 'n', substr( $payload, $off + 2, 2 ) );
        $off += $NTP_SUBOPT_HDR_LEN;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated NtpServer sub-option' )
            if $off + $slen > $len;
        my $sv = substr( $payload, $off, $slen );
        $off += $slen;
        my $decoder = $SUBOPT_DECODE{$sc};
        if ( $decoder ) {
            push @decoded, $decoder->( $sv );
        }
        else {
            push @decoded, { subopt => $sc, value => $sv };
        }
    }
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated NtpServer sub-option header' )
        if $off != $len;
    return $class->new( entries => \@decoded );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_NTP_SERVER} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::NtpServer - NTP Server option (code 56) -- sub-options for NTP configuration per RFC 5908

=head1 VERSION

version 0.003

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
