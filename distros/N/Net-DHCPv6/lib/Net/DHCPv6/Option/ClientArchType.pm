#!/usr/bin/false
# ABSTRACT: Client System Architecture Type option (code 61) — 16-bit architecture type
# PODNAME: Net::DHCPv6::Option::ClientArchType
package Net::DHCPv6::Option::ClientArchType;
$Net::DHCPv6::Option::ClientArchType::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientArchType requires type' unless defined $args{type};
    $args{code} = $OPTION_CLIENT_ARCH_TYPE;
    $args{data} = pack( 'n', $args{type} );
    my $self = $class->SUPER::new( %args );
    $self->{type} = $args{type};
    bless $self, $class;
}

sub type { shift->{type} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'ClientArchType must be exactly 2 bytes' )
        if CORE::length( $data ) != 2;
    my $type = unpack( 'n', $data );
    return $class->new( type => $type );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'n', $self->{type} );
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENT_ARCH_TYPE} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::ClientArchType - Client System Architecture Type option (code 61) — 16-bit architecture type

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ClientArchType;
  my $opt = Net::DHCPv6::Option::ClientArchType->new(type => 0);

=head1 DESCRIPTION

Carries a 16-bit client system architecture type per RFC 5970
(e.g. 0 = x86 BIOS, 6 = EFI x86-64).

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<type>, a 16-bit unsigned integer.

=head2 type

Returns the architecture type code.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
