=head1 PURPOSE

Check that struct aliases are lexical, but can be made permanent
using the C<< -retain >> flag.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

{
	package Local::Foo1;
	use MooX::Struct
		Bar => [qw($name)],
	;
	
	::ok(
		Bar->can('name'),
		'Bar class available inside Local::Foo1',
	);
}

{
	package Local::Foo2;
	use MooX::Struct -retain,
		Bar => [qw($name)],
	;
	
	::ok(
		Bar->can('name'),
		'Bar class available inside Local::Foo2',
	);
}

::ok(
	!'Local::Foo1'->can('Bar'),
	"Bar class unavailable outside Local::Foo1",
);

::ok(
	'Local::Foo2'->can('Bar'),
	"Bar class available outside Local::Foo2",
);

::ok(
	Local::Foo2::Bar->can('name'),
	"Bar class works outside Local::Foo2",
);

done_testing;
