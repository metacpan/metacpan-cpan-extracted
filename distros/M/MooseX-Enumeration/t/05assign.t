=pod

=encoding utf-8

=head1 PURPOSE

Test delegation to C<assign>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 6;
use Test::Fatal;

{
	package Local::Test;
	use Moose;
	
	has status => (
		traits  => ['Enumeration'],
		is      => 'ro',
		enum    => [qw/ foo bar baz quux /],
		handles => {
			map(+("is_$_"=>"is_$_"), qw/ foo bar baz quux /),
			make_foo          => [ assign => "foo" ],
			make_foo_if_bar   => [ assign => "foo", "bar" ],
			make_foo_if_ba    => [ assign => "foo", qr{^ba} ],
			make_bar          => [ assign => "bar" ],
			make_baz          => [ assign => "baz" ],
			make_quux         => [ assign => "quux", ["bar", "baz"] ],
		}
	);
};

my $obj = Local::Test->new(status => "baz");

like(
	exception { $obj->make_foo_if_bar },
	qr/^Method make_foo_if_bar cannot be called when attribute status has value baz/,
	'threw exception making transition disallowed by eq check',
);

is(
	exception { $obj->make_foo_if_ba },
	undef,
	'no exception thrown making allowed transition',
);

ok($obj->is_foo, '... and transition made correctly');

is(
	exception { $obj->make_foo_if_ba },
	undef,
	'no exception thrown when transition is a no-op',
);

$obj->make_bar->make_quux;

ok($obj->is_quux, 'chained transition works');

like(
	exception { $obj->make_foo_if_ba },
	qr/^Method make_foo_if_ba cannot be called when attribute status has value quux/,
	'threw exception making transition disallowed by match::simple::match',
);
