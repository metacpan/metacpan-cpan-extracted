BEGIN {
    # A hack to suppress redefined warning caused by circulation dependency
    $INC{'Test/AutoMock/Mock/Functions.pm'} //= do {
        require File::Spec;
        File::Spec->rel2abs(__FILE__);
    };
}

package Test::AutoMock::Mock::Functions;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw(blessed);

# Load classes after @EXPORT_OK creation
BEGIN { our @EXPORT_OK = qw(new_mock get_manager) }
use Test::AutoMock::Manager;
use Test::AutoMock::Mock::Basic;
use Test::AutoMock::Mock::Overloaded;

sub new_mock ($@) {
    my $class = shift;

    my $mock = bless(\ my $manager, $class);
    $manager = Test::AutoMock::Manager->new(
        @_,
        mock_class => $class,
        mock => $mock,
    );

    $mock;
}

sub get_manager ($) {
    my $mock = shift;

    my $class = blessed $mock or die '$mock is not an object';

    bless $mock, __PACKAGE__ . "::Dummy";  # disable operator overloads
    my $deref = eval { $$mock };

    bless $mock, $class;
    $@ and die $@;

    $deref;
}

1;

=encoding utf-8

=head1 NAME

Test::AutoMock::Mock::Functions - Functions to manipulate mocks

=head1 DESCRIPTION

This module provides methods of L<Test::AutoMock::Mock::Basic>.

We defined these methods into different packages so as not to affect
the behavior of the mock.

Rather than using this class directly, it would be more convenient to use
a wrapper defined for L<Test::AutoMock>.

=head1 FUNCTIONS

=head2 C<new_mock>

  my $mock1 = new_mock('Test::AutoMock::Mock::Basic');
  my $mock2 = new_mock(
      'Test::AutoMock::Mock::Overloaded',
      methods => { 'some->method' => 1 },
  );

This is a constructor. Pass in the name of the class to instantiate as
the first argument.

=head2 C<get_manager>

Get the manager object of the mock.

=head1 SEE ALSO

=over 4

=item L<Test::AutoMock>

=item L<Test::AutoMock::Mock::Basic>

=item L<Test::AutoMock::Mock::Overloaded>

=back

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

