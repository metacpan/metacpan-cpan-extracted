#!/bin/false
# ABSTRACT: AFTR Name option (code 88) -- RFC 6334 domain name
# PODNAME: Net::DHCPv6::Option::AftrName
use strictures 2;

package Net::DHCPv6::Option::AftrName;
$Net::DHCPv6::Option::AftrName::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Option;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
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

sub _decode_domain {
    my ( $payload ) = @_;
    return $EMPTY unless CORE::length( $payload );
    my $offset = 0;
    my @labels = _read_labels_at( $payload, \$offset, CORE::length( $payload ) );
    return join( '.', @labels );
}

sub new {
    my ( $class, %args ) = @_;
    croak 'AftrName requires domain_name' unless defined $args{domain_name};
    $args{code} = $OPTION_AFTR_NAME;
    $args{data} = _encode_domain( $args{domain_name} );
    my $self = $class->SUPER::new( %args );
    $self->{domain_name} = $args{domain_name};
    return bless $self, $class;
}

sub domain_name { return shift->{domain_name} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my $name = _decode_domain( $payload );
    return $class->new( domain_name => $name );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_AFTR_NAME} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::AftrName - AFTR Name option (code 88) -- RFC 6334 domain name

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::AftrName;
  my $opt = Net::DHCPv6::Option::AftrName->new(
      domain_name => 'aftr.example.com',
  );

=head1 DESCRIPTION

Carries the domain name of the AFTR (Address Family Transition
Router) for DS-Lite tunnels.  See RFC 6334.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<domain_name>.

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
