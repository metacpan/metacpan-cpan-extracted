=pod

=encoding utf-8

=head1 PURPOSE

Test that a more complex MooseX::Enumeration delegation works.

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
use Test::More tests => 3;

{
	package Local::Test;
	use Moose;
	
	has status => (
		traits  => ['Enumeration'],
		is      => 'ro',
		enum    => [qw/ foo bar baz /],
		handles => {
			starts_with_ba => ["is" => qr{^ba}],
		}
	);
};

ok( not Local::Test->new(status => "foo")->starts_with_ba );
ok( Local::Test->new(status => "bar")->starts_with_ba );
ok( Local::Test->new(status => "baz")->starts_with_ba );
