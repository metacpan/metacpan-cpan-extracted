=head1 PURPOSE

Check that structs can consume Moo roles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

BEGIN {
	package Local::Role1;
	use Moo::Role;
	has attr1 => (is => 'ro');
}

BEGIN {
	package Local::Role2;
	use Moo::Role;
	has attr2 => (is => 'ro');
}

use MooX::Struct
	Thingy => [
		-with  => [qw( Local::Role2 Local::Role1 )],
		qw/ $attr3 $attr4 /,
	],
;

is_deeply(
	[ Thingy->FIELDS ],
	[ qw/ attr3 attr4 / ],
);

my $thingy = Thingy[qw/ 3 4 /];
#is($thingy->attr1, 1);
#is($thingy->attr2, 2);
is($thingy->attr3, 3);
is($thingy->attr4, 4);

$thingy = Thingy->new(map { ; "attr$_", $_ } 1..4);
is($thingy->attr1, 1);
is($thingy->attr2, 2);
is($thingy->attr3, 3);
is($thingy->attr4, 4);

done_testing;
