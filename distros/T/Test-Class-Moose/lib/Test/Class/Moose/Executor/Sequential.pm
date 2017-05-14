package Test::Class::Moose::Executor::Sequential;

# ABSTRACT: Execute tests sequentially

use 5.10.0;

our $VERSION = '0.83';

use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Executor::Sequential - Execute tests sequentially

=head1 VERSION

version 0.83

=for Pod::Coverage Tags Tests runtests

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/test-class-moose/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/test-class-moose/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2017 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
