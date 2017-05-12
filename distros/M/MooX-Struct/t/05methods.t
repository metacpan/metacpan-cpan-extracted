=head1 PURPOSE

Check that methods can be added to structs.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 1;
use MooX::Struct
	Person => [
		qw( name age sex ),
		uc_name => sub {
			my $self = shift;
			return uc $self->name;
		},
	];

is(Person->new(name => 'Bob')->uc_name, 'BOB');
