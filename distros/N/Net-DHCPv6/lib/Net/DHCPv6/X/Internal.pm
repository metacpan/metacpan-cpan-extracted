#!/bin/false
# ABSTRACT: Thrown on internal logic errors in the library
# PODNAME: Net::DHCPv6::X::Internal
use strictures 2;

package Net::DHCPv6::X::Internal;
$Net::DHCPv6::X::Internal::VERSION = '0.003';
use parent 'Net::DHCPv6::X';
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::X::Internal - Thrown on internal logic errors in the library

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::DHCPv6;

    # Internal exceptions indicate a library bug and are not expected
    # under normal use. They propagate through decode_with_error.
    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    if ($err && $err->isa('Net::DHCPv6::X::Internal')) {
        warn "internal error: " . $err->message;
    }

=head1 DESCRIPTION

Exception thrown when an internal logic error occurs in the library.
This should never happen under normal use and indicates a bug.

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
