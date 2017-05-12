=head1 PURPOSE

Check the experimental C<EXTEND> method.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;
use MooX::Struct Point => [qw( +x +y )];

my $point = Point[];
my $old_id = $point->OBJECT_ID;

is($point->TYPE, 'Point');
is_deeply([$point->FIELDS], ['x', 'y']);
ok( $point->can('x'));
ok( $point->can('y'));
ok(!$point->can('z'));

$point->EXTEND(\"Point3D", '+z');

is($point->TYPE, 'Point3D');
is_deeply([$point->FIELDS], ['x', 'y', 'z']);
ok( $point->can('x'));
ok( $point->can('y'));
ok( $point->can('z'));

is($point->OBJECT_ID, $old_id, 'OBJECT_ID does not change during EXTEND');

my $new = $point->CLONE(z => 0)->EXTEND(\"Point4D", '+w');
is_deeply([$point->FIELDS], ['x', 'y', 'z']);
is_deeply([$new->FIELDS], ['x', 'y', 'z', 'w']);

isnt($new->OBJECT_ID, $old_id, 'OBJECT_ID does change during CLONE+EXTEND');

use MooX::Struct Person => ['$name'];

my $Employee = Person->EXTEND(\"Employee", '$title');
isa_ok($Employee, Person);

my $bob = $Employee->new(['Robert', 'Staff']);
isa_ok($bob, $Employee);
isa_ok($bob, Person);
is($bob->TYPE, 'Employee');
is_deeply([$bob->FIELDS], [qw/ name title /]);
is($bob->name, 'Robert');
is($bob->title, 'Staff');
ok !eval { $bob->title('Manager') };  # read-only

my $PromotableEmployee = Person->EXTEND(-rw, \"PromotableEmployee", '$title');
isa_ok($PromotableEmployee, Person);
my $alice = $PromotableEmployee->new(['Alice', 'Staff']);
isa_ok($alice, $PromotableEmployee);
isa_ok($alice, Person);
is($alice->TYPE, 'PromotableEmployee');
is_deeply([$alice->FIELDS], [qw/ name title /]);
is($alice->name, 'Alice');
is($alice->title, 'Staff');
$alice->title('Manager');  # read-write
is($alice->title, 'Manager');

done_testing;
