=pod

=encoding utf-8

=head1 PURPOSE

Test that C<< handles => 2 >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 4;

{
	package Local::Test;
	use Moose;
	
	has status => (
		traits  => ['Enum'],
		is      => 'ro',
		enum    => [qw/ foo bar /],
		handles => 2,
	);
};

{
	my $obj = Local::Test->new(status => "foo");
	ok($obj->status_is_foo);
	ok(not $obj->status_is_bar);
}

{
	my $obj = Local::Test->new(status => "bar");
	ok(not $obj->status_is_foo);
	ok($obj->status_is_bar);
}
