#!/bin/false
# ABSTRACT: Domain Search List option (code 24) -- RFC 1035 domain names
# PODNAME: Net::DHCPv6::Option::DomainList
use strictures 2;

package Net::DHCPv6::Option::DomainList;
$Net::DHCPv6::Option::DomainList::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Option;
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw( is_plain_arrayref );
use namespace::clean;
my $EMPTY         = q();
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

sub _decode_domains {
    my ( $payload ) = @_;
    my @domain_list;
    my $offset = 0;
    my $len    = CORE::length( $payload );
    while ( $offset < $len ) {
        my @labels = _read_labels_at( $payload, \$offset, $len );
        push @domain_list, @labels ? join( '.', @labels ) : $EMPTY;
    }
    return \@domain_list;
}

sub new {
    my ( $class, %args ) = @_;
    my $domains = $args{domains} // $args{data} // [];
    $domains    = [$domains] unless is_plain_arrayref( $domains );
    $args{code} = $OPTION_DOMAIN_LIST;
    $args{data} = join( $EMPTY, map { _encode_domain( $_ ) } @{$domains} );
    my $self = $class->SUPER::new( %args );
    $self->{domains} = $domains;
    return bless $self, $class;
}

sub domains { return shift->{domains} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my $domains = _decode_domains( $payload );
    return $class->new( domains => $domains );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_DOMAIN_LIST} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::DomainList - Domain Search List option (code 24) -- RFC 1035 domain names

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::DomainList;
  my $opt = Net::DHCPv6::Option::DomainList->new(
      domains => [ 'example.com', 'example.org' ],
  );

=head1 DESCRIPTION

Carries a list of domain names for the client's DNS domain search
path, encoded as RFC 1035 length-prefixed labels.  See RFC 3646.

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
