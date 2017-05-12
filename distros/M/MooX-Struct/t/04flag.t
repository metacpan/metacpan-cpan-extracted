=head1 PURPOSE

Check that the "-rw" flag works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More tests => 1;
use MooX::Struct -rw,
	Agent        => [qw( name )],
	Person       => [ -extends => ['Agent'] ];

my $bob   = Person->new(name => 'Bob');

note sprintf("Agent class:         %s", Agent);
note sprintf("Person class:        %s", Person);

$bob->name('Robert');
is($bob->name, 'Robert');
