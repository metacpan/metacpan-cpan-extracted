#!/bin/false
# ABSTRACT: Thrown when a message header is invalid
# PODNAME: Net::DHCPv6::X::BadMessage
use strictures 2;

package Net::DHCPv6::X::BadMessage;
$Net::DHCPv6::X::BadMessage::VERSION = '0.003';
use parent 'Net::DHCPv6::X';
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::X::BadMessage - Thrown when a message header is invalid

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    if ($err && $err->isa('Net::DHCPv6::X::BadMessage')) {
        warn "bad message: " . $err->message;
    }

=head1 DESCRIPTION

Exception thrown when a DHCPv6 message header is invalid or corrupt,
such as an unrecognised message type or truncated header.

See L<Net::DHCPv6::X>.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
