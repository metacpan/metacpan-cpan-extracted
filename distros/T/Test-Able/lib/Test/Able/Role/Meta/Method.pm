package Test::Able::Role::Meta::Method;

use Moose::Role;
use strict;
use warnings;

with qw( Test::Able::Planner );

=head1 NAME

Test::Able::Role::Meta::Method - Method metarole

=head1 DESCRIPTION

This metarole gets applied to the Moose::Meta::Method metaclass objects that
represent methods in a Test::Able-based class or role.  This metarole also
pulls in L<Test::Able::Planner>.

=head1 ATTRIBUTES

=over

=item type

Type of test method.  See L<Test::Able::Role::Meta::Class/method_types> for
the list.

=cut

has 'type' => ( is => 'rw', isa => 'Str|Undef', );

=item do_setup

Only relevant for methods of type test.  Boolean indicating whether
to run the associated setup methods.

=cut

has 'do_setup' => ( is => 'rw', isa => 'Bool', lazy_build => 1, );

=item do_teardown

Only relevant for methods of type test.  Boolean indicating whether
to run the associated teardown methods.

=cut

has 'do_teardown' => ( is => 'rw', isa => 'Bool', lazy_build => 1, );

=item order

An integer value used to influence ordering of methods in the method lists.
Defaults to 0.

=back

=cut

has 'order' => ( is => 'rw', isa => 'Int', lazy_build => 1, );

sub _build_do_setup { return 1; }

sub _build_do_teardown { return 1; }

sub _build_plan { return 0; }

sub _build_order { return 0; }

=head1 AUTHOR

Justin DeVuyst, C<justin@devuyst.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Justin DeVuyst.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
