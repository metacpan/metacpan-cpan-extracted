=head1 PURPOSE

See if L<MooX::HandlesVia> support works.

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

use Test::Requires { "MooX::HandlesVia" => "0.001004" };

{
	package Local::ThingyContainer;
	use Moo;
	use MooX::late;
	
	has _thingies => (
		traits  => ['Array'],
		is      => 'ro',
		isa     => 'ArrayRef[Str]',
		default => sub { [] },
		handles => {
			all   => 'elements',
			add   => 'push',
			count => 'count',
		},
	);
}

{
	package Local::Foo;
	use Moo;
	use MooX::late;
	
	has code => (
		traits  => ['Code'],
		is      => 'ro',
		isa     => 'CodeRef',
		handles => {
			e  => 'execute',
			em => 'execute_method',
		},
	);
}

my $c = 'Local::ThingyContainer'->new;

is($c->count, 0);

$c->add(qw/ Foo Bar Baz /);
$c->add(qw/ Quux /);

is($c->count, 4);

is_deeply(
	[ $c->all ],
	[qw/ Foo Bar Baz Quux /],
);

my $x = 'Local::Foo'->new(code => sub { [@_] });

is_deeply(
	$x->e(1..3),
	[1..3],
);

is_deeply(
	$x->em(1..3),
	[$x, 1..3],
);

done_testing;
