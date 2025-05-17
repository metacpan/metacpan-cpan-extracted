package Test::Class::Moose::Report::Instance;

# ABSTRACT: Reporting on test classes

use strict;
use warnings;
use namespace::autoclean;

use 5.010000;

our $VERSION = '1.00';

use Moose;
use Carp;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_startup_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_startup_method',
);

has test_shutdown_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_shutdown_method',
);

has test_methods => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Test::Class::Moose::Report::Method]',
    default => sub { [] },
    handles => {
        all_test_methods => 'elements',
        add_test_method  => 'push',
        num_test_methods => 'count',
    },
);

sub current_method {
    my $self = shift;
    return $self->test_methods->[-1];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Report::Instance - Reporting on test classes

=head1 VERSION

version 1.00

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

See L<Test::Class::Moose::Role::Reporting> for additional attributes.

=head2 C<class>

The L<Test::Class::Moose::Report::Class> for this instance.

=head2 C<all_test_methods>

Returns an array of L<Test::Class::Moose::Report::Method> objects.

=head2 C<current_method>

Returns the current (really, most recent) L<Test::Class::Moose::Report::Method>
object that is being run.

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
