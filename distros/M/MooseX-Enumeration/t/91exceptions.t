=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Enumeration throws exceptions when used incorrectly.

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
use Test::More tests => 1;
use Test::Fatal;

my $e = exception {
	package Local::Test;
	use Moose;
	
	has status => (
		traits  => ['Enumeration'],
		is      => 'ro',
		enum    => [qw/ foo bar /],
		handles => [qw/ is_foo is_bar is_baz /],
	);
};

like($e, qr{^Value "baz" did not pass type constraint});
