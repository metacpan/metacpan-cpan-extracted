package Stepford::Grapher::Role::Renderer;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '1.01';

use Moose::Role;

with 'MooseX::Getopt::Dashes';

requires 'render';

no Moose::Role;
1;

# ABSTRACT: Base role for all Stepford::Grapher renderers

__END__

=pod

=encoding UTF-8

=head1 NAME

Stepford::Grapher::Role::Renderer - Base role for all Stepford::Grapher renderers

=head1 VERSION

version 1.01

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/Stepford-Grapher/issues>.

=head1 AUTHOR

Mark Fowler <mfowler@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2017 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
