#!/bin/false
# ABSTRACT: Thrown when option data violates expected format
# PODNAME: Net::DHCPv6::X::BadOption
use strictures 2;

package Net::DHCPv6::X::BadOption;
$Net::DHCPv6::X::BadOption::VERSION = '0.003';
use parent 'Net::DHCPv6::X';
use namespace::clean;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::X::BadOption - Thrown when option data violates expected format

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    if ($err && $err->isa('Net::DHCPv6::X::BadOption')) {
        warn "bad option: " . $err->message;
    }

=head1 DESCRIPTION

Exception thrown when option data cannot be parsed, for example
truncated option content or invalid field values.

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
