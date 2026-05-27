#!/usr/bin/false
# ABSTRACT: Vendor Class option (code 16) — enterprise-number + opaque data
# PODNAME: Net::DHCPv6::Option::VendorClass
package Net::DHCPv6::Option::VendorClass;
$Net::DHCPv6::Option::VendorClass::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'VendorClass requires enterprise_number' unless defined $args{enterprise_number};
    $args{code} = $OPTION_VENDOR_CLASS;
    my $data_list = $args{vendor_data} // $args{data} // [];
    $data_list = [$data_list] unless is_plain_arrayref( $data_list );
    my $encoded =
        pack( 'N', $args{enterprise_number} ) . join( '', map { pack( 'n', CORE::length ) . $_ } @$data_list );
    $args{data} = $encoded;
    my $self = $class->SUPER::new( %args );
    $self->{enterprise_number} = $args{enterprise_number};
    $self->{vendor_data}       = $data_list;
    bless $self, $class;
}

sub enterprise_number { shift->{enterprise_number} }
sub vendor_data       { shift->{vendor_data} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated VendorClass option' )
        if CORE::length( $data ) < 4;
    my $en   = unpack( 'N', substr( $data, 0, 4 ) );
    my $rest = substr( $data, 4 );
    my @items;
    my $offset = 0;
    my $len    = CORE::length( $rest );
    while ( $offset + 2 <= $len ) {
        my $ilen = unpack( 'n', substr( $rest, $offset, 2 ) );
        $offset += 2;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated VendorClass data item' )
            if $offset + $ilen > $len;
        push @items, substr( $rest, $offset, $ilen );
        $offset += $ilen;
    }
    return $class->new( enterprise_number => $en, vendor_data => \@items );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_VENDOR_CLASS} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::VendorClass - Vendor Class option (code 16) — enterprise-number + opaque data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::VendorClass;
  my $opt = Net::DHCPv6::Option::VendorClass->new(
      enterprise_number => 9,
      vendor_data       => [ 'foo', 'bar' ],
  );

=head1 DESCRIPTION

Conveys vendor-class information consisting of an IANA enterprise
number and one or more opaque data items.  See RFC 8415 §21.16.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<enterprise_number>.  Optional C<vendor_data>
(arrayref of opaque strings, defaults to empty list).

=head2 enterprise_number

Returns the IANA enterprise number.

=head2 vendor_data

Returns an arrayref of opaque vendor data items.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
