## skip Test::Tabs

=pod

=encoding utf-8

=head1 PURPOSE

Test MooX::Traits::Util works.

=head1 DEPENDENCIES

This test requires L<Moo> and L<Test::Fatal>.
Otherwise, it will be skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on C<< class.t >> from the L<MooseX::Traits> test suite,
by Jonathan Rockway and Karen Etheridge.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster, Jonathan Rockway, and Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { 'Test::Fatal' => '0' };
{ package AAA; use Test::Requires { 'Moo' => '1.000000' } };
use Test::More tests => 10;

{ package Trait;
  use Moo::Role;
  has 'foo' => (
      is       => 'ro',
      required => 1,
  );

  package Class;
  use Moo;
  with 'MooX::Traits';

  package Another::Trait;
  use Moo::Role;
  has 'bar' => (
      is       => 'ro',
      required => 1,
  );

  package Another::Class;
  use Moo;
  with 'MooX::Traits';
  sub _trait_namespace { 'Another' };

  package YetAnother::Class;
  use Moo;
  # NOT with 'MooX::Traits';
  sub _trait_namespace { 'Another' };

}

use MooX::Traits::Util qw(new_class_with_traits);

isnt
    exception { new_class_with_traits( 'OH NOES', 'Trait' ); },
    undef,
    'OH NOES is not a MX::Traits class';

is
    exception { new_class_with_traits( 'Moo', 'Trait' ); },
    undef,
    'Moose::Meta::Class is not a MX::Traits class';

my $class;
is
    exception { $class = new_class_with_traits( 'Another::Class' => 'Trait' ); },
    undef,
    'new_class_with_traits works';

ok $class;

my $instance = $class->new( foo => '42', bar => '24' );
ok not $instance->can('foo');
is $instance->bar, 24;

my $class2;
is
    exception { $class2 = new_class_with_traits( 'YetAnother::Class' => 'Trait' ); },
    undef,
    'new_class_with_traits works';

ok $class2;

my $instance2 = $class2->new( foo => '42', bar => '24' );
is $instance2->foo, 42;
ok not $instance2->can('bar');
