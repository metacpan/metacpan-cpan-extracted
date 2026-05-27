#!/usr/bin/false
# ABSTRACT: Client FQDN option (code 39) — flags + domain name
# PODNAME: Net::DHCPv6::Option::ClientFqdn
package Net::DHCPv6::Option::ClientFqdn;
$Net::DHCPv6::Option::ClientFqdn::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
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

sub _decode_domain {
    my ( $data ) = @_;
    return '' unless CORE::length( $data );
    my $offset = 0;
    my @labels = _read_labels_at( $data, \$offset, CORE::length( $data ) );
    return join( '.', @labels );
}

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientFqdn requires flags' unless defined $args{flags};
    croak 'ClientFqdn flags must be 0-255'
        if $args{flags} < 0 || $args{flags} > 255;
    $args{code} = $OPTION_CLIENT_FQDN;
    my $domain = _encode_domain( $args{domain_name} // '' );
    $args{data} = pack( 'C', $args{flags} ) . $domain;
    my $self = $class->SUPER::new( %args );
    $self->{flags}       = $args{flags};
    $self->{domain_name} = $args{domain_name} // '';
    bless $self, $class;
}

sub flags       { shift->{flags} }
sub domain_name { shift->{domain_name} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated ClientFqdn option' )
        if CORE::length( $data ) < 1;
    my $flags = unpack( 'C', substr( $data, 0, 1 ) );
    my $name  = _decode_domain( substr( $data, 1 ) );
    return $class->new( flags => $flags, domain_name => $name );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENT_FQDN} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::ClientFqdn - Client FQDN option (code 39) — flags + domain name

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ClientFqdn;
  my $opt = Net::DHCPv6::Option::ClientFqdn->new(
      flags       => 0x01,
      domain_name => 'client.example.com',
  );

=head1 DESCRIPTION

Carries the client's fully qualified domain name together with
flag bits that control DNS update behaviour.  See RFC 4704.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<flags> (0-255) and optional C<domain_name>.

=head2 flags

Returns the flag byte.

=head2 domain_name

Returns the domain name string.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
