package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use strict;
use warnings;
use namespace::autoclean;

use 5.010000;

our $VERSION = '1.00';

use Moose 2.0000;
use Carp;
with 'Test::Class::Moose::Role::Executor';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Executor::Sequential - Execute tests sequentially

=head1 VERSION

version 1.00

=for Pod::Coverage Tags Tests runtests

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/Test-More/test-class-moose/issues>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/Test-More/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Chad Granum <exodist@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2025 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
