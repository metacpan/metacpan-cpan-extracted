package Test::AutoMock;
use 5.010;
use strict;
use warnings;
use Exporter qw(import);
use Test::AutoMock::Mock::Functions qw(new_mock get_manager);

our $VERSION = "0.01";

our @EXPORT_OK = qw(mock mock_overloaded manager);

sub mock { new_mock('Test::AutoMock::Mock::Basic', @_) }

sub mock_overloaded { new_mock('Test::AutoMock::Mock::Overloaded', @_) }

sub manager ($) {
    my $mock = shift;
    get_manager $mock;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock - A mock that can be used with a minimum setup

=head1 SYNOPSIS

  use Test::AutoMock qw(mock manager);
  use Test::More import => [qw(is note done_testing)];

  # a black box function you want to test
  sub get_metacpan {
      my $ua = shift;
      my $response = $ua->get('https://metacpan.org/');
      if ($response->is_success) {
          return $response->decoded_content;  # or whatever
      }
      else {
          die $response->status_line;
      }
  }

  # build and set up the mock
  my $mock_ua = mock(
      methods => {
          # implement only the method you are interested in
          'get->decoded_content' => "Hello, metacpan!\n",
      },
  );

  # action first
  my $body = get_metacpan($mock_ua);

  # then, assertion
  is $body, "Hello, metacpan!\n";
  manager($mock_ua)->called_with_ok('get->is_success' => []);
  manager($mock_ua)->not_called_ok('get->status_line');

  # print all recorded calls
  for (manager($mock_ua)->calls) {
      my ($method, $args) = @$_;
      note "$method(" . join(', ', @$args) . ")";
  }

=head1 DESCRIPTION

Test::AutoMock is a mock module designed to be used with a minimal setup.
AutoMock can respond to any method call and returns a new AutoMock instance
as a return value. Therefore, you can use it as a mock object without having
to define all the methods. Even if method calls are nested, there is no
problem.

AutoMock records all method calls on all descendants. You can verify the method
calls and its arguments after using the mock. This is not the "record and
replay" model but the "action and assertion" model.

You can also mock many overloaded operators and hashes, arrays with
L<Test::AutoMock::Mock::Overloaded>. If you want to apply monkey patch to use
AutoMock, check L<Test::AutoMock::Patch>.

Test::AutoMock is inspired by Python3's unittest.mock module.

=head1 ALPHA WARNING

This module is under development. The API, including names of classes and
methods, may be subject to BACKWARD INCOMPATIBLE CHANGES.

=head1 FUNCTIONS

=head2 C<mock>

  my $mock = mock(
      methods => {
          agent => 'libwww-perl/AutoMock',
          'get->is_success' => sub { 1 },
      },
      isa => 'LWP::UserAgent',
  );

Create L<Test::AutoMock::Mock::Basic> instance. It takes the following
parameters.

=over 4

=item C<methods>

A hash-ref of method definitions. See L<Test::AutoMock::Manager::add_method>.

=item C<isa>

A super class of this mock. See L<Test::AutoMock::Manager::isa>.
To specify multiple classes, use array-ref.

=back

=head2 C<mock_overloaded>

It is the same as the mock method except that the generated instance is
L<Test::AutoMock::Mock::Overloaded>.

=head2 C<manager>

Access the L<Test::AutoMock::Manager> of the mock instance. You can set up and
verify the mock with the Manager object. See L<Test::AutoMock::Manager>
for details.

All L<Test::AutoMock::Mock::Basic> and L<Test::AutoMock::Mock::Overloaded>
instances have the Manager class. The manager and the mock correspond one to
one. In fact, C<< manager($mock)->mock == $mock >> and
C<< manager($manager->mock) == $manager >> hold.

=head1 SEE ALSO

=over 4

=item L<Test::AutoMock::Manager>

=item L<Test::MockObject>

=item L<Test::Double>

=item L<Test::Stub>

=item L<Test::Mocha>

=back

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

