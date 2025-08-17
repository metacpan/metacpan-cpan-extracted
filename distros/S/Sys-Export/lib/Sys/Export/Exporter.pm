package Sys::Export::Exporter;

our $VERSION = '0.003'; # VERSION
# ABSTRACT: base class for exporters, only used for 'isa' checks

use v5.26;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Export::Exporter - base class for exporters, only used for 'isa' checks

=head1 INTERFACE

Every exporter should support the following attributes:

=over

=item src

A source filesystem path

=item dst

A destination path, or object having methods 'add' and 'finish' (like Sys::Export::CPIO)

=back

and the following methods:

=over

=item add

=item finish

=back

=head1 VERSION

version 0.003

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
