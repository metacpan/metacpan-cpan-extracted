# ABSTRACT: Member names validation utility
package PONAPI::Names;

use strict;
use warnings;

use parent qw< Exporter >;
our @EXPORT_OK = qw< check_name >;

my $qr_edge = qr/[a-zA-Z0-9\P{ASCII}]/;
my $qr_mid  = qr/[a-zA-Z0-9\P{ASCII}_\ -]/;

sub check_name {
    my $name = shift;

    return if ref($name);
    return if length($name) == 0;

    return $name =~ /\A $qr_edge          \z/x if length($name) == 1;
    return $name =~ /\A $qr_edge $qr_edge \z/x if length($name) == 2;
    return $name =~ /\A $qr_edge $qr_mid+ $qr_edge \z/x;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PONAPI::Names - Member names validation utility

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

    use PONAPI::Names 'check_name';

    check_name('a');    # Valid
    check_name('a-');   # Invalid
    check_name('-a');   # Invalid
    check_name('a-b');  # Valid
    check_name('a b');  # Valid

=head1 DESCRIPTION

This module implements the L<member name restrictions|http://jsonapi.org/format/#document-member-names>
from the {json:api} specification; it can be used by repositories
to implement strict member names, if desired.

=head1 AUTHORS

=over 4

=item *

Mickey Nasriachi <mickey@cpan.org>

=item *

Stevan Little <stevan@cpan.org>

=item *

Brian Fraser <hugmeir@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Mickey Nasriachi, Stevan Little, Brian Fraser.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
