package Test::AutoMock::Patch;
use strict;
use warnings;
use Exporter qw(import);
use Test::AutoMock qw(mock_overloaded);

our @EXPORT_OK = qw(patch_sub);

sub _patch_sub_one {
    my ($code, $subroutines, $mocks) = @_;
    my ($subroutine, @left_subroutines) = @$subroutines;

    my $mock = mock_overloaded;
    my @new_mocks = (@$mocks, $mock);

    no strict 'refs';
    no warnings 'redefine';
    local *$subroutine = sub { $mock };

    @left_subroutines
        ? _patch_sub_one($code, \@left_subroutines, \@new_mocks)
        : $code->(@new_mocks);
}

sub patch_sub (&@) {
    my ($code, @subroutines) = @_;
    _patch_sub_one $code, \@subroutines, [];
}

1;
__END__

=encoding utf-8

=head1 NAME

Test::AutoMock::Patch - Monkey patch for returning AutoMock

=head1 SYNOPSIS

  use Test::AutoMock::Patch qw(patch_sub);

  # a black box function you want to test
  sub get_metacpan {
      my $ua = LWP::UserAgent->new;
      my $response = $ua->get('https://metacpan.org/');
      if ($response->is_success) {
          return $response->decoded_content;  # or whatever
      }
      else {
          die $response->status_line;
      }
  }

  # apply a monkey patch to LWP::UserAgent::new
  patch_sub {
      my $mock = shift;

      # set up the mock
      manager($mock)->add_method('get->decoded_content' => "Hello, metacpan!\n");

      # call blackbox function
      my $body = get_metacpan();

      # assertions
      is $body, "Hello, metacpan!\n";
      manager($mock)->called_with_ok('get->is_success' => []);
      manager($mock)->not_called_ok('get->status_line');
  } 'LWP::UserAgent::new';

=head1 DESCRIPTION

Temporarily replace any subroutine and return AutoMock. It is convenient when
mock can not be injected from outside.

=head1 FUNCTIONS

=head2 C<patch_sub>

    patch_sub {
        my ($mock, $other_mock) = @_;

        # write your test using $mock

    } 'Path::To::subroutine', 'Path::To::other_subroutine';

Replace the specified subroutine with one that returns a mock, and execute
the code in the block. The mock object is passed as the argument of the block
by the number of replaced subroutines. After exiting the block, the patch is
removed.

The generated mock object is an instance of
L<Test::AutoMock::Mock::Overloaded>.

It is a common usage to patch the class method used as a constructor.

=head1 LICENSE

Copyright (C) Masahiro Honma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Honma E<lt>hiratara@cpan.orgE<gt>

=cut

