#!/bin/false
# ABSTRACT: Client FQDN option (code 39) -- flags + domain name
# PODNAME: Net::DHCPv6::Option::ClientFqdn
use strictures 2;

package Net::DHCPv6::Option::ClientFqdn;
$Net::DHCPv6::Option::ClientFqdn::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Option;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY         = q();
my $MAX_BYTE      = 255;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $MAX_PTR_DEPTH = 255;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub _encode_domain {
    my ( $domain ) = @_;
    return chr( 0 ) unless defined $domain && CORE::length( $domain );
    my @labels = split m/[.]/, $domain;
    return join( $EMPTY, map { pack( 'C', CORE::length ) . $_ } @labels ) . chr( 0 );
}

sub _read_labels_at {
    my ( $payload, $offset_ref, $len, $depth ) = @_;
    $depth //= 0;
    my @labels;
    while ( ${$offset_ref} < $len ) {
        my $llen = unpack( 'C', substr( $payload, ${$offset_ref}, 1 ) );
        if ( $llen == 0 ) {
            ++${$offset_ref};
            last;
        }
        if ( ( $llen & $DN_COMPRESS_MASK ) == $DN_COMPRESS_MASK ) {    ## no critic (Bangs::ProhibitBitwiseOperators ValuesAndExpressions::ProhibitMagicNumbers)
            if ( $Net::DHCPv6::Option::FOLLOW_COMPRESSION ) {
                Net::DHCPv6::X::Truncated->throw( message => 'Truncated compression pointer' )
                    if ${$offset_ref} + 2 > $len;
                my $ptr =
                    ( ( $llen & $DN_LABEL_MASK ) << 8 ) | unpack( 'C', substr( $payload, ${$offset_ref} + 1, 1 ) );    ## no critic (Bangs::ProhibitBitwiseOperators ValuesAndExpressions::ProhibitMagicNumbers)
                Net::DHCPv6::X::BadOption->throw( message => 'Compression pointer out of range' )
                    if $ptr >= $len;
                Net::DHCPv6::X::BadOption->throw( message => 'Compression pointer depth exceeded' )
                    if $depth > $MAX_PTR_DEPTH;
                ${$offset_ref} += 2;
                my $ptr_ref = \$ptr;
                push @labels, _read_labels_at( $payload, $ptr_ref, $len, $depth + 1 );
                last;
            }
            Net::DHCPv6::X::BadOption->throw( message => 'Compression pointer in domain name' );
        }
        Net::DHCPv6::X::BadOption->throw( message => 'Invalid domain label length' ) if $llen > $DN_LABEL_MASK;
        ++${$offset_ref};
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated domain label' )
            if ${$offset_ref} + $llen > $len;
        push @labels, substr( $payload, ${$offset_ref}, $llen );
        ${$offset_ref} += $llen;
    }
    return @labels;
}

sub _decode_domain {
    my ( $payload ) = @_;
    return $EMPTY unless CORE::length( $payload );
    my $offset = 0;
    my @labels = _read_labels_at( $payload, \$offset, CORE::length( $payload ) );
    return join( '.', @labels );
}

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientFqdn requires flags' unless defined $args{flags};
    croak 'ClientFqdn flags must be 0-255'
        if $args{flags} < 0 || $args{flags} > $MAX_BYTE;
    $args{code} = $OPTION_CLIENT_FQDN;
    my $domain = _encode_domain( $args{domain_name} // $EMPTY );
    $args{data} = pack( 'C', $args{flags} ) . $domain;
    my $self = $class->SUPER::new( %args );
    $self->{flags}       = $args{flags};
    $self->{domain_name} = $args{domain_name} // $EMPTY;
    return bless $self, $class;
}

sub flags       { return shift->{flags} }
sub domain_name { return shift->{domain_name} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated ClientFqdn option' )
        if CORE::length( $payload ) < 1;
    my $flags = unpack( 'C', substr( $payload, 0, 1 ) );
    my $name  = _decode_domain( substr( $payload, 1 ) );
    return $class->new( flags => $flags, domain_name => $name );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENT_FQDN} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ClientFqdn - Client FQDN option (code 39) -- flags + domain name

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ClientFqdn;
  use Net::DHCPv6::Constants qw($CLIENT_FQDN_S);

  my $opt = Net::DHCPv6::Option::ClientFqdn->new(
      flags       => $CLIENT_FQDN_S,
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
