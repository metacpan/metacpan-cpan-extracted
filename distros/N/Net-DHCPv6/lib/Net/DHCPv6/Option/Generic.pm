#!/usr/bin/false
# ABSTRACT: Fallback option for unknown codes — stores raw code+data
# PODNAME: Net::DHCPv6::Option::Generic
package Net::DHCPv6::Option::Generic;
$Net::DHCPv6::Option::Generic::VERSION = '0.001';
use strictures 2;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    return $class->new( code => $code, data => $data );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::Generic - Fallback option for unknown codes — stores raw code+data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);
    my $opt = $msg->options->get_option(999);  # unknown code
    my $data = $opt->data if $opt;

    # Or construct directly
    use Net::DHCPv6::Option::Generic;
    my $gen = Net::DHCPv6::Option::Generic->new(code => 123, data => "\x00\x01");

=head1 DESCRIPTION

Pass-through container for option codes with no dedicated subclass.
Stores the raw code and data intact, enabling lossless re-encoding of
unknown options. When a parse failure occurs in a known option class
and the error is a Net::DHCPv6::X exception, the option falls back
to Generic to preserve data.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 SEE ALSO

L<Net::DHCPv6::Option>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
