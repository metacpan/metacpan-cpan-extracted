=pod

=encoding utf-8

=head1 PURPOSE

Check that type constraints are checked when using lvalue accessors.

Also tests that MooseX::LvalueAttribute can export its constant.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Goose;
	use Moose;
	use MooseX::LvalueAttribute lvalue => { -as => 'lv' };
	has name => (traits => [ lv ], is => 'rw', isa => 'Str');
}

my $mother = Goose->new(name => 'Mother Goose');

$mother->name('Ma Goose');
is($mother->name, 'Ma Goose', 'changed name via parameter');

like(
	exception { $mother->name([]) },
	qr{^Attribute .?name.? does not pass the type constraint because: Validation failed for .?Str.?},
	'exception when attempting to set invalid name via parameter'
);
is($mother->name, 'Ma Goose', '... and attribute value was not changed');

$mother->name = 'Mammy Goose';
is($mother->name, 'Mammy Goose', 'changed name via lvalue');

like(
	exception { $mother->name = {} },
	qr{^Attribute .?name.? does not pass the type constraint because: Validation failed for .?Str.?},
	'exception when attempting to set invalid name via lvalue'
);
is($mother->name, 'Mammy Goose', '... and attribute value was not changed');

done_testing;
