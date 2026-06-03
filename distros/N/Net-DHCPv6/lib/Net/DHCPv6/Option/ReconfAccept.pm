#!/bin/false
# ABSTRACT: Reconfigure Accept option (code 20) -- zero-length data
# PODNAME: Net::DHCPv6::Option::ReconfAccept
use strictures 2;

package Net::DHCPv6::Option::ReconfAccept;
$Net::DHCPv6::Option::ReconfAccept::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_RECONF_ACCEPT
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_RECONF_ACCEPT;
    return $class->SUPER::new( %args );
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_RECONF_ACCEPT} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ReconfAccept - Reconfigure Accept option (code 20) -- zero-length data

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ReconfAccept;
  my $opt = Net::DHCPv6::Option::ReconfAccept->new;

=head1 DESCRIPTION

Zero-length option used by a server to indicate that the client should
accept reconfiguration.  See RFC 8415 E<167>21.22.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Takes no parameters.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
