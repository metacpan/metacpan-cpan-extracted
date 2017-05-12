=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Enumeration works with Type::Tiny type constraints.

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
use Test::Requires { 'Types::Standard' => '0.030' };
use Test::More tests => 5;

{
	package Local::Test;
	use Moose;
	use Types::Standard qw(Enum);
	
	has status => (
		traits  => ['Enumeration'],
		is      => 'ro',
		isa     => Enum[qw/ foo bar /],
		handles => 1,
	);
};

is_deeply(
	[sort @{ Local::Test->meta->get_attribute('status')->enum }],
	[sort qw( foo bar )],
);

{
	my $obj = Local::Test->new(status => "foo");
	ok($obj->is_foo);
	ok(not $obj->is_bar);
}

{
	my $obj = Local::Test->new(status => "bar");
	ok(not $obj->is_foo);
	ok($obj->is_bar);
}
