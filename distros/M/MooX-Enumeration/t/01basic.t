=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::Enumeration works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 4;

{
	package Local::Test;
	use Moo;
	use MooX::Enumeration;
	
	has status => (
		is      => 'ro',
		enum    => [qw/ foo bar /],
		handles => 1,
	);
};

#is_deeply(
#	[sort @{ Local::Test->meta->get_attribute('status')->enum }],
#	[sort qw( foo bar )],
#);

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
