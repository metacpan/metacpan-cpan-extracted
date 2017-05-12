use 5.10.1;
use strict;
use warnings;

package Stenciller::Utils;

our $VERSION = '0.1400'; # VERSION:

use Moose::Role;

sub eval_to_hashref {
    my $self = shift;
    my $possible_hash = shift; # Str
    my $faulty_file = shift;   # Path|Str

    my $settings = eval $possible_hash;
    die sprintf "Can't parse stencil start: <%s> in %s: %s", $possible_hash, $faulty_file, $@ if $@;
    return $settings;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stenciller::Utils

=head1 VERSION

Version 0.1400, released 2016-02-03.

=head1 SOURCE

L<https://github.com/Csson/p5-Stenciller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Stenciller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
