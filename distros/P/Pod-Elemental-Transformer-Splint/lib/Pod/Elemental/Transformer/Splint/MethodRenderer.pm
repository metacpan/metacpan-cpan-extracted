use 5.10.1;
use strict;
use warnings;

package Pod::Elemental::Transformer::Splint::MethodRenderer;

our $VERSION = '0.1201'; # VERSION
# ABSTRACT: Role for method renderers

use Moose::Role;
use Pod::Simple::XHTML;
use Types::Standard qw/Str/;

with 'Pod::Elemental::Transformer::Splint::Util';
requires 'render_method';

has for => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Elemental::Transformer::Splint::MethodRenderer - Role for method renderers

=head1 VERSION

Version 0.1201, released 2016-02-03.

=head1 SOURCE

L<https://github.com/Csson/p5-Pod-Elemental-Transformer-Splint>

=head1 HOMEPAGE

L<https://metacpan.org/release/Pod-Elemental-Transformer-Splint>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
