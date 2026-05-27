#!/usr/bin/false
# ABSTRACT: Thrown when a buffer is too short for expected data
# PODNAME: Net::DHCPv6::X::Truncated
package Net::DHCPv6::X::Truncated;
$Net::DHCPv6::X::Truncated::VERSION = '0.001';
use strictures 2;
use parent 'Net::DHCPv6::X';
use namespace::clean;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::X::Truncated - Thrown when a buffer is too short for expected data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($short_bytes);
    if ($err && $err->isa('Net::DHCPv6::X::Truncated')) {
        warn "truncated: " . $err->message;
    }

=head1 DESCRIPTION

Exception thrown when a buffer is shorter than the expected header
or data length during wire-format parsing.

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
