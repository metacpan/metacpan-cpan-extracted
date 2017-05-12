## skip Test::Tabs

=pod

=encoding utf-8

=head1 PURPOSE

Test that C<new_with_traits> works.

(Most of the other tests use C<with_traits>.)

=head1 DEPENDENCIES

This test requires L<Moo> and L<Test::Fatal>.
Otherwise, it will be skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on C<< with-traits.t >> from the L<MooseX::Traits> test suite,
by Jonathan Rockway and Karen Etheridge.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster, Jonathan Rockway, and Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { 'Test::Fatal' => '0' };
use Test::Requires { 'Moo' => '1.000000' };
use Test::More tests => 22;
use Test::Fatal;

{ package Trait;
  use Moo::Role;
  has 'foo' => (
      is       => 'ro',
      isa      => sub { defined($_[0]) && !ref($_[0]) or die },
      required => 1,
  );

  package Class;
  use Moo;
  with 'MooX::Traits';

  package Another::Trait;
  use Moo::Role;
  has 'bar' => (
      is       => 'ro',
      isa      => sub { defined($_[0]) && !ref($_[0]) or die },
      required => 1,
  );

  package Another::Class;
  use Moo;
  with 'MooX::Traits';
  sub _trait_namespace { 'Another' }

}

foreach my $trait ( 'Trait', ['Trait' ] ) {
    my $instance = Class->new_with_traits( traits => $trait, foo => 'hello' );
    isa_ok $instance, 'Class';
    can_ok $instance, 'foo';
    is $instance->foo, 'hello';
}

like
    exception { Class->new_with_traits( traits => ['Trait'] ); },
    qr/required/,
    'foo is required';

{
    my $instance = Class->new_with_traits;
    isa_ok $instance, 'Class';
    ok !$instance->can('foo'), 'this one cannot foo';
}
{
    my $instance = Class->new_with_traits( traits => [] );
    isa_ok $instance, 'Class';
    ok !$instance->can('foo'), 'this one cannot foo either';
}
{
    my $instance = Another::Class->new_with_traits( traits => ['Trait'], bar => 'bar' );
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}
# try hashref form
{
    my $instance = Another::Class->new_with_traits({ traits => ['Trait'], bar => 'bar' });
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'bar';
    is $instance->bar, 'bar';
}
{
    my $instance = Another::Class->new_with_traits(
        traits   => ['Trait', '+Trait'],
        foo      => 'foo',
        bar      => 'bar',
    );
    isa_ok $instance, 'Another::Class';
    can_ok $instance, 'foo';
    can_ok $instance, 'bar';
    is $instance->foo, 'foo';
    is $instance->bar, 'bar';
}
