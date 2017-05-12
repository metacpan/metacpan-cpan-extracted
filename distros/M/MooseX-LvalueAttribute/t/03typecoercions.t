=pod

=encoding utf-8

=head1 PURPOSE

Check that type coercions work with lvalue accessors.

(Also checks C<< ++ >> and C<< += >> work.)

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
	
	use Moose::Util::TypeConstraints;
	subtype 'Count',
		as 'Int', where { $_ >= 0 };
	coerce 'Count',
		from 'Num', via { int($_) };
	
	use MooseX::LvalueAttribute;
	has eggs => (traits => ['Lvalue'], is => 'rw', isa => 'Count', coerce => 1);
}

my $mother = Goose->new(eggs => 1.1);

is($mother->eggs, 1, 'coercion worked in constructor');

$mother->eggs++;

is($mother->eggs, 2, 'postfix increment worked');

++$mother->eggs;

is($mother->eggs, 3, 'prefix increment worked');

$mother->eggs += 1.4;

is($mother->eggs, 4, '+= assignment with coercion worked');

$mother->eggs = 5.1;

is($mother->eggs, 5, 'normal assignment with coercion worked');

done_testing;
