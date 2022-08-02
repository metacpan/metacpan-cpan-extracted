package Perl::Critic::Freenode::Utils;

use strict;
use warnings;
use Perl::Critic::Community::Utils qw(is_empty_return is_structural_block);
use Exporter 'import';

our $VERSION = 'v1.0.3';

our @EXPORT_OK = qw(is_empty_return is_structural_block);

1;

=head1 NAME

Perl::Critic::Freenode::Utils - Empty shim for Perl::Critic::Community::Utils

=head1 DESCRIPTION

Legacy exporter for utility functions from L<Perl::Critic::Community::Utils>.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>, L<Perl::Critic::Community>
