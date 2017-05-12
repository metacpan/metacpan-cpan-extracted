## skip Test::Tabs

=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::Traits works on subclasses of base classes that consume
it.

=head1 DEPENDENCIES

This test requires L<Moo> and L<Test::Fatal>.
Otherwise, it will be skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on C<< subclass.t >> from the L<MooseX::Traits> test suite,
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
use Test::More tests => 3;
use Test::Fatal;

{ package Foo;
  use Moo;
  with 'MooX::Traits';

  package Bar;
  use Moo;
  extends 'Foo';

  package Trait;
  use Moo::Role;

  sub foo { return 42 };
}

my $instance;
is
    exception {
        $instance = Bar->new_with_traits( traits => ['Trait'] );
    },
    undef,
    'creating instance works ok';

ok $instance->does('Trait'), 'instance does trait';
is $instance->foo, 42, 'trait works';
