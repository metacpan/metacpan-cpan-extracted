package MooseX::Test::Parameter::Moose;

use Moose;

use Moose::Util::TypeConstraints;
use Test::More;
use Test::Moose;
use Test::Exception;

our $VERSION = '0.01';

our $AUTHORITY = 'cpan:BERLE';

sub planned { 24 }

sub test {
  my ($self,$class) = @_;

  # basic

  {
    my $parameter = $class->new;

    isa_ok ($parameter,$class);

    does_ok ($parameter,'MooseX::Meta::Parameter');
  
    is ($parameter->validate (42),42);

    ok (!$parameter->validate);
  }

  # required

  {
    my $parameter = $class->new (required => 1);

    throws_ok { $parameter->validate } qr/Must be specified/;

    #  is ($parameter->validate (42),42);
  }

  # type constraint

  {
    my $parameter = $class->new (isa => 'Int');

    is ($parameter->validate (42),42);

    throws_ok { $parameter->validate ('Foo') } qr/Argument isn't/;
  }

  # type constraint - anonymous subtypes

  {
    my $parameter = $class->new (isa => subtype ('Int',where { $_ < 5 }));

    throws_ok { $parameter->validate (42) } qr/Argument isn't/;
  }

  throws_ok { $class->new (isa => bless ({},'Foo')) } qr/You cannot specify an object as type/;

  # type constraint - classes

  {
    my $parameter = $class->new (isa => 'Foo');

    throws_ok { $parameter->validate (42) } qr/Argument isn't/;

    ok (ref $parameter->validate (bless ({},'Foo')) eq 'Foo');
  }

  # type constraint - unions

  {
    my $parameter = $class->new (isa => 'Int | ArrayRef');

    throws_ok { $parameter->validate ('Foo') } qr/Argument isn't/;

    is ($parameter->validate (42),42);

    is_deeply ($parameter->validate ([42]),[42]);
  }

  # default value

  {
    my $parameter = $class->new (default => 42);

    is ($parameter->validate,42);
  }

  # default coderef

  {
    my $parameter = $class->new (default => sub { 42 });

    is ($parameter->validate,42);
  }

  # coerce

  subtype 'SmallInt'
    => as 'Int'
    => where { $_ < 10 };

  coerce 'SmallInt'
    => from 'Int'
      => via { 5 };

  throws_ok { $class->new (coerce => 1) } qr/does not support this/;

  throws_ok { $class->new (isa => 'Int',coerce => 1) } qr/does not support this/;
    
  {
    my $parameter = $class->new (isa => 'SmallInt',coerce => 1);

    throws_ok { $parameter->validate ('Foo') } qr/Argument isn't/;

    is ($parameter->validate (42,1),5);
  }

  # does

  {
    package Foo::Role;

    use Moose::Role;
  }

  {
    package Foo1;

    sub new { bless {},$_[0] }
  }

  {
    package Foo2;

    use Moose;
  }

  {
    package Foo3;

    use Moose;

    with qw/Foo::Role/;
  }

  {
    my $parameter = $class->new (does => 'Foo::Role');

    throws_ok { $parameter->validate ('Foo') } qr/Does not do/;

    throws_ok { $parameter->validate (Foo1->new) } qr/Does not do/;

    throws_ok { $parameter->validate (Foo2->new) } qr/Does not do/;

    lives_ok { $parameter->validate (Foo3->new) };
  }

  return;
}

1;

__END__

=pod

=head1 NAME

MooseX::Test::Parameter::Moose - Testsuite for Moose parameters

=head1 WARNING

This API is unstable, it may change at any time. This should not
affect ordinary L<MooseX::Method> usage.

=head1 SYNOPSIS

  use MooseX::Test::Parameter::Moose;
  use Test::More;

  my $tester = MooseX::Test::Parameter::Moose->new;

  plan tests => $tester->planned;

  $tester->test ('MooseX::Meta::Parameter::Moose');

=head1 DESCRIPTION

A testsuite for Moose style parameters. If you intend to implement
your own optimized version of the parameter, please use this suite to
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

