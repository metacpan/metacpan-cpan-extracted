package MooseX::Test::Signature::Named;

use Moose;

use Moose::Util::TypeConstraints;
use Test::More;
use Test::Moose;
use Test::Exception;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub planned { 11 };

sub test {
  my ($self,$class) = @_;

  # basic

  {
    my $signature = $class->new;

    isa_ok ($signature,$class);

    does_ok ($signature,'MooseX::Meta::Signature');

    is_deeply ($signature->validate (foo => 1),{ foo => 1 });

    is_deeply ($signature->validate ({ foo => 1 }),{ foo => 1 });
  }

  # specified

  {
    my $signature = $class->new (foo => { required => 1 });

    throws_ok { $signature->validate ({}) } qr/Parameter \(foo\): Must be specified/;
  }

  # custom parameter

  {
    package Foo::Parameter;

    use Moose;

    with qw/MooseX::Meta::Parameter/;

    sub validate { 42 };
  }

  {
    throws_ok { $class->new (foo => 0) } qr/Parameter must be/;

    throws_ok { $class->new (foo => bless ({},'Foo')) } qr/Parameter must be/;

    my $signature = $class->new (foo => Foo::Parameter->new);

    is_deeply ($signature->validate ({ foo => 1 }),{ foo => 42 });
  }

  # custom metaclass

  {
    my $signature = $class->new (foo => { metaclass => 'Foo::Parameter' });

    is_deeply ($signature->validate ({ foo => 1 }),{ foo => 42 });
  }

  # exception handling

  {
    my $signature = $class->new (foo => { isa => subtype ('Int',where { die 'Foo' }) });

    throws_ok { $signature->validate (foo => 43) } qr/Foo/;
  }

  {
    my $signature = $class->new (foo => { isa => subtype ('Int',where { die bless ({},'Foo') }) });

    eval { $signature->validate (foo => 43) };

    is (ref $@,'Foo');
  }

  return;
}

1;

__END__

=pod

=head1 NAME

MooseX::Test::Signature::Named - Testsuite for named signatures

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Test::Signature::Named;
  use Test::More;

  my $tester = MooseX::Test::Signature::Named->new;

  plan tests => $tester->planned;

  $tester->test ('MooseX::Meta::Signature::Named');

=head1 DESCRIPTION

A testsuite for named signatures. If you intend to implement your own
optimized version of the signature, please use this suite to verify
that it's compatible.

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

