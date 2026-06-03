#!/bin/false
# ABSTRACT: Client System Architecture Type option (code 61) -- 16-bit architecture type
# PODNAME: Net::DHCPv6::Option::ClientArchType
use strictures 2;

package Net::DHCPv6::Option::ClientArchType;
$Net::DHCPv6::Option::ClientArchType::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_CLIENT_ARCH_TYPE
);
use Net::DHCPv6::X::BadOption ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientArchType requires type' unless defined $args{type};
    $args{code} = $OPTION_CLIENT_ARCH_TYPE;
    $args{data} = pack( 'n', $args{type} );
    my $self = $class->SUPER::new( %args );
    $self->{type} = $args{type};
    return bless $self, $class;
}

sub type { return shift->{type} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'ClientArchType must be exactly 2 bytes' )
        if CORE::length( $payload ) != 2;
    my $type = unpack( 'n', $payload );
    return $class->new( type => $type );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENT_ARCH_TYPE} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ClientArchType - Client System Architecture Type option (code 61) -- 16-bit architecture type

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ClientArchType;
  use Net::DHCPv6::Constants qw($CLIENT_ARCH_X86_UEFI arch_name);

  my $opt = Net::DHCPv6::Option::ClientArchType->new(
      type => $CLIENT_ARCH_X86_UEFI
  );
  print arch_name( $opt->type );  # X86_UEFI

=head1 DESCRIPTION

Carries a 16-bit client system architecture type per RFC 5970.
Common types include:

=over

=item C<$CLIENT_ARCH_X86_BIOS> (0) -- x86 BIOS

=item C<$CLIENT_ARCH_X86_UEFI> (6) -- x86 UEFI

=item C<$CLIENT_ARCH_ARM_64_UEFI> (11) -- ARM 64-bit UEFI

=back

All 42 IANA-registered architecture types are available as constants in
L<Net::DHCPv6::Constants/"Client Architecture Types (RFC 5970)">.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<type>, a 16-bit unsigned integer matching one of
the C<$CLIENT_ARCH_*> constants.

=head2 type

Returns the architecture type code.

=head1 SEE ALSO

L<Net::DHCPv6::Constants/"Client Architecture Types (RFC 5970)">,
L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
