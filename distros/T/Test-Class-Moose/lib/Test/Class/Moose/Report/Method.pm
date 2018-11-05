package Test::Class::Moose::Report::Method;

# ABSTRACT: Reporting on test methods

use 5.010000;

our $VERSION = '0.95';

use Moose;
use Carp;
use namespace::autoclean;
use Test::Class::Moose::AttributeRegistry;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_setup_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_setup_method',
);

has test_teardown_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_teardown_method',
);

has 'instance' => (
    is       => 'ro',
    isa      => 'Test::Class::Moose::Report::Instance',
    required => 1,
    weak_ref => 1,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'tests_planned' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_plan',
);

sub plan {
    my ( $self, $integer ) = @_;
    $self->tests_planned( ( $self->tests_planned || 0 ) + $integer );
}

sub has_tag {
    my ( $self, $tag ) = @_;
    croak("has_tag(\$tag) requires a tag name") unless defined $tag;
    my $class  = $self->instance->class->name;
    my $method = $self->name;
    return Test::Class::Moose::AttributeRegistry->method_has_tag(
        $class,
        $method,
        $tag
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Report::Method - Reporting on test methods

=head1 VERSION

version 0.95

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=for Pod::Coverage plan

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

See L<Test::Class::Moose::Role::Reporting> for additional attributes.

=head2 C<instance>

The L<Test::Class::Moose::Report::Instance> for this method.

=head2 C<num_tests_run>

    my $tests_run = $method->num_tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.

=head2 C<has_tag>

    my $method = $test->test_report->current_method;
    if ( $method->has_tag('db') ) {
        $test->load_database_fixtures;
    }

Returns true if the current test method has the tag in question.

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/test-class-moose/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Test-Class-Moose can be found at L<https://github.com/houseabsolute/test-class-moose>.

=head1 AUTHORS

=over 4

=item *

Curtis "Ovid" Poe <ovid@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2018 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
