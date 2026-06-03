#!/bin/false
# ABSTRACT: Relay-Supplied Options option (code 66) -- opaque
# PODNAME: Net::DHCPv6::Option::RSOO
use strictures 2;

package Net::DHCPv6::Option::RSOO;
$Net::DHCPv6::Option::RSOO::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_RSOO
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_RSOO;
    $args{data} = $args{data} // ( $args{option_data} // $EMPTY );
    return $class->SUPER::new( %args );
}

sub option_data { return shift->{data} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new( option_data => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_RSOO} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::RSOO - Relay-Supplied Options option (code 66) -- opaque

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::RSOO;
  my $opt = Net::DHCPv6::Option::RSOO->new(option_data => $bytes);

=head1 DESCRIPTION

Opaque container for options supplied by a relay agent and
returned in server responses.  See RFC 8415 E<167>21.24.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<option_data> (raw bytes, defaults to empty).

=head2 option_data

Returns the relay-supplied option data bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
