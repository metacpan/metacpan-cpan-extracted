=head1 PURPOSE

Shared test code for C<< t/01json.t >> and C<< t/02sereal.t >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;

package t::Accessors;
use Test::More;

sub checker
{
	shift;
	my $class = shift;
	my $obj;
	
	return sub
	{
		plan tests => 11;
		ok eval qq{ require $class };
		
		$obj = new_ok($class);
		
		can_ok($obj, qw( fetch store delete exists keys values ));
		$obj->store(foo => 42);

		is($obj->fetch('foo'), 42, 'fetch/store works');

		$obj->store(bar => 99);
		is_deeply([$obj->keys], [qw/bar foo/], 'keys works');
		is_deeply([$obj->values], [qw/99 42/], 'values works');

		ok($obj->exists('foo') && $obj->exists('bar') && !$obj->exists('baz'), 'exists works');

		is($obj->delete('foo'), 42, 'delete returns correct value');
		ok($obj->exists('bar') && !$obj->exists('foo'), 'delete modifies structure');

		$obj->clear;
		is_deeply([$obj->keys], [], 'clear works');

		$obj->store(xxx => [1..3]);
		is($obj->fetch('xxx')->[1], 2, 'nested structures stored correctly');
	};
}

1;
