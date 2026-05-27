#!/usr/bin/false
# ABSTRACT: SIP Server Domain Name option (code 21) — list of domain names
# PODNAME: Net::DHCPv6::Option::SipServerD
package Net::DHCPv6::Option::SipServerD;
$Net::DHCPv6::Option::SipServerD::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;

sub _encode_domain {
    my ( $domain ) = @_;
    return "\x00" unless defined $domain && CORE::length( $domain );
    my @labels = split m/\./, $domain;
    join( '', map { pack( 'C', CORE::length ) . $_ } @labels ) . "\x00";
}

sub _read_labels_at {
    my ( $data, $offset_ref, $len ) = @_;
    my @labels;
    while ( $$offset_ref < $len ) {
        my $llen = unpack( 'C', substr( $data, $$offset_ref, 1 ) );
        if ( $llen == 0 ) {
            ++$$offset_ref;
            last;
        }
        if ( ( $llen & 0xC0 ) == 0xC0 ) {
            if ( $Net::DHCPv6::Option::FOLLOW_COMPRESSION ) {
                Net::DHCPv6::X::Truncated->throw( message => 'Truncated compression pointer' )
                    if $$offset_ref + 2 > $len;
                my $ptr = ( ( $llen & 0x3F ) << 8 ) | unpack( 'C', substr( $data, $$offset_ref + 1, 1 ) );
                Net::DHCPv6::X::BadOption->throw( message => 'Compression pointer out of range' )
                    if $ptr >= $len;
                $$offset_ref += 2;
                my $ptr_ref = \$ptr;
                push @labels, _read_labels_at( $data, $ptr_ref, $len );
                last;
            }
            Net::DHCPv6::X::BadOption->throw( message => 'Compression pointer in domain name' );
        }
        Net::DHCPv6::X::BadOption->throw( message => 'Invalid domain label length' ) if $llen > 63;
        ++$$offset_ref;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated domain label' )
            if $$offset_ref + $llen > $len;
        push @labels, substr( $data, $$offset_ref, $llen );
        $$offset_ref += $llen;
    }
    return @labels;
}

sub _decode_domains {
    my ( $data ) = @_;
    my @domains;
    my $offset = 0;
    my $len    = CORE::length( $data );
    while ( $offset < $len ) {
        my @labels = _read_labels_at( $data, \$offset, $len );
        push @domains, @labels ? join( '.', @labels ) : '';
    }
    return \@domains;
}

sub new {
    my ( $class, %args ) = @_;
    my $domains = $args{domains} // $args{data} // [];
    $domains    = [$domains] unless is_plain_arrayref( $domains );
    $args{code} = $OPTION_SIP_SERVER_D;
    $args{data} = join( '', map { _encode_domain( $_ ) } @$domains );
    my $self = $class->SUPER::new( %args );
    $self->{domains} = $domains;
    bless $self, $class;
}

sub domains { shift->{domains} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    my $domains = _decode_domains( $data );
    return $class->new( domains => $domains );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SIP_SERVER_D} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::SipServerD - SIP Server Domain Name option (code 21) — list of domain names

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::SipServerD;
  my $opt = Net::DHCPv6::Option::SipServerD->new(
      domains => [ 'sip.example.com', 'sip.example.org' ],
  );

=head1 DESCRIPTION

Carries a list of domain names of SIP outbound proxy servers
available to the client, encoded as RFC 1035 length-prefixed
labels per RFC 3319.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<domains> (arrayref of domain strings).

=head2 domains

Returns an arrayref of domain name strings.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
