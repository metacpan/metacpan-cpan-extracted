package MooseX::Test::Signature::Combined;

use Moose;

use MooseX::Meta::Signature::Combined;
use Test::More;
use Test::Moose;
use Test::Exception;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub planned { 4 }

sub test {
  my ($self,$class) = @_;

  # basic

  {
    my $signature = $class->new ({});

    isa_ok ($signature,$class);

    does_ok ($signature,'MooseX::Meta::Signature');

    is_deeply ([$signature->validate (42,foo => 1)],[42,{ foo => 1 }]);
  }

  # specified (only positional)

  {
    my $signature = $class->new ({},foo => {});

    throws_ok { $signature->validate } qr/Parameter 0: Must be specified/;
  }

  return;
}

1;

__END__

=pod

=head1 NAME

MooseX::Test::Signature::Combined - Testsuite for combined signatures

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Test::Signature::Combined;
  use Test::More;

  my $tester = MooseX::Test::Signature::Combined->new;

  plan tests => $tester->planned;

  $tester->test ('MooseX::Meta::Signature::Combined');

=head1 DESCRIPTION

A testsuite for combined signatures. If you intend to implement your
own optimized version of the signature, please use this suite to
verify that it's compatible.

=head1 METHODS

=over 4

=item planned

The number of planned tests.

=item test

Tests the specified class for conformity.

=back

=head1 BUGS

Most software has bugs. This module probably isn't an exception.
If you find a bug please either email me, or add the bug to cpan-RT.

=head1 AUTHOR

Anders Nor Berle E<lt>debolaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Anders Nor Berle.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

