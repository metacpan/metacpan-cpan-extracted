#!/bin/false
# ABSTRACT: Boot File Parameters option (code 60) -- list of boot parameters
# PODNAME: Net::DHCPv6::Option::BootfileParam
use strictures 2;

package Net::DHCPv6::Option::BootfileParam;
$Net::DHCPv6::Option::BootfileParam::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw( is_plain_arrayref );
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_BOOTFILE_PARAM;
    my $data_list = $args{parameters} // [];
    $data_list = [$data_list] unless is_plain_arrayref( $data_list );
    $args{data} = join( $EMPTY, map { pack( 'n', CORE::length ) . $_ } @{$data_list} );
    my $self = $class->SUPER::new( %args );
    $self->{parameters} = $data_list;
    return bless $self, $class;
}

sub parameters { return shift->{parameters} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my @items;
    my $offset = 0;
    my $len    = CORE::length( $payload );
    while ( $offset + 2 <= $len ) {
        my $ilen = unpack( 'n', substr( $payload, $offset, 2 ) );
        $offset += 2;
        Net::DHCPv6::X::Truncated->throw( message => 'Truncated BootfileParam item' )
            if $offset + $ilen > $len;
        push @items, substr( $payload, $offset, $ilen );
        $offset += $ilen;
    }
    return $class->new( parameters => \@items );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_BOOTFILE_PARAM} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::BootfileParam - Boot File Parameters option (code 60) -- list of boot parameters

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::BootfileParam;
  my $opt = Net::DHCPv6::Option::BootfileParam->new(
      parameters => [ "\x00\x01", "\x02\x03" ],
  );

=head1 DESCRIPTION

Carries a list of opaque boot parameter strings for network boot.
Each parameter is length-prefixed (16-bit).  See RFC 5970.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<parameters> (arrayref of opaque strings).

=head2 parameters

Returns an arrayref of opaque parameter strings.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
