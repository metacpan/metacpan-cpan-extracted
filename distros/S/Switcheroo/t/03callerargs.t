=pod

=encoding utf-8

=head1 PURPOSE

Test using C<< @_ >> within C<switch> blocks.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Switcheroo;

sub switcher
{
	switch ($_[0]) {
		case 0, 6:  $_[2];
		default:    { $_[1] };
	}
}

is(switcher(0, 'weekday', 'weekend'), 'weekend');
is(switcher($_, 'weekday', 'weekend'), 'weekday') for 1..5;
is(switcher(6, 'weekday', 'weekend'), 'weekend');

sub switcher2
{
	switch ($_[0]) {
		case $_[1]:  1;
		case $_[2]:  2;
		default:     0;
	}
}

is( switcher2('foo', 'foo', 'bar'), 1 );
is( switcher2('bar', 'foo', 'bar'), 2 );
is( switcher2('baz', 'foo', 'bar'), 0 );
is( switcher2('foo', sub { 1 }, sub { 1 }), 1 );
is( switcher2('foo', sub { 0 }, sub { 1 }), 2 );
is( switcher2('foo', sub { 0 }, sub { 0 }), 0 );

{
	local $TODO = 'it would be awesome if this worked';
	
	sub switcher3
	{
		# caller_args(1) doesn't notice this modification to @_
		my $dummy = shift(@_);
		
		switch ($_[0]) {
			case $_[1]:  1;
			case $_[2]:  2;
			default:     0;
		}
	}
	
	is( switcher3('DUMMY', 'foo', 'foo', 'bar'), 1 );
	is( switcher3('DUMMY', 'bar', 'foo', 'bar'), 2 );
	is( switcher3('DUMMY', 'baz', 'foo', 'bar'), 0 );
	is( switcher3('DUMMY', 'foo', sub { 1 }, sub { 1 }), 1 );
	is( switcher3('DUMMY', 'foo', sub { 0 }, sub { 1 }), 2 );
	is( switcher3('DUMMY', 'foo', sub { 0 }, sub { 0 }), 0 );
}

done_testing;

