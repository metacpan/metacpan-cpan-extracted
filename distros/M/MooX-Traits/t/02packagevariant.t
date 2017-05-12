## skip Test::Tabs

=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::Traits can compose L<Package::Variant>-based roles,
and pass arguments to them.

=head1 DEPENDENCIES

This test requires L<Moo>, L<Package::Variant> and L<Test::Fatal>.
Otherwise, it will be skipped.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on C<< parameterized.t >> from the L<MooseX::Traits> test suite,
by Jonathan Rockway, Tomas Doran, and Karen Etheridge.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster, Jonathan Rockway, Tomas Doran, and Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Requires { 'Test::Fatal' => '0' };
{ package AAA; use Test::Requires { 'Moo' => '1.000000' } };
{ package BBB; use Test::Requires { 'Package::Variant' => '0' } };
use Test::More;
use Test::Fatal;

plan tests => 11;

{
    package Role;
    use Moo::Role;

    has 'gorge' => (
        is       => 'ro',
        required => 1,
    );
}

{
    package PRole;
    use Package::Variant
        importing => ['Moo::Role'],
        subs      => [ qw(has around before after with) ];
    
    sub make_variant {
        my ($class, $target_package, %p) = @_;
        has $p{foo} => (
            is       => 'ro',
            required => 1,
        );
    }
}

{
    package Class;
    use Moo;

    with 'MooX::Traits';
}

is
    exception { Class->new; },
    undef,
    'making class is OK';

is
    exception { Class->new_with_traits; },
    undef,
    'making class with no traits is OK';

my $a;

is
    exception {
        $a = Class->new_with_traits(
            traits => ['PRole' => { foo => 'OHHAI' }],
            OHHAI  => 'I FIXED THAT FOR YOU',
        );
    },
    undef,
    'prole is applied OK';

isa_ok $a, 'Class';
is $a->OHHAI, 'I FIXED THAT FOR YOU', 'OHHAI accessor works';

is
    exception {
        undef $a;
        $a = Class->new_with_traits(
            traits => ['PRole' => { foo => 'OHHAI' }, 'Role'],
            OHHAI  => 'I FIXED THAT FOR YOU',
            gorge  => 'three rivers',
        );
    },
    undef,
    'prole is applied OK along with a normal role';

can_ok $a, 'OHHAI', 'gorge';

is
    exception {
        undef $a;
        $a = Class->new_with_traits(
            traits => ['Role', 'PRole' => { foo => 'OHHAI' }],
            OHHAI  => 'I FIXED THAT FOR YOU',
            gorge  => 'columbia river',
        );
    },
    undef,
    'prole is applied OK along with a normal role (2)';

can_ok $a, 'OHHAI', 'gorge';

is
    exception {
        undef $a;
        $a = Class->new_with_traits(
            traits => ['Role' => { bullshit => 'params', go => 'here' }],
            gorge  => 'i should have just called this foo',
        );
    },
    undef,
    'regular roles with args can be applied, but args are ignored';

can_ok $a, 'gorge';
