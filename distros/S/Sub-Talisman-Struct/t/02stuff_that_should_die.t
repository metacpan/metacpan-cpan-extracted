=head1 PURPOSE

Checks that talisman parameters are validated by L<MooX::Struct>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 4;
use Test::NoWarnings;
use strict;
use warnings;

subtest 'isa checks' => sub {
	package Local::XXX1;
	use Sub::Talisman::Struct
		XXX => [qw( +number )],
	;

	::plan tests => 4;
	::ok eval q{ sub foo1 :XXX(123) { 1 }; 1 }, 'valid value';
	::ok eval q{ sub foo2 :XXX { 1 }; 1 }, 'no value';
	::ok !eval q{ sub foo3 :XXX("Hello") { 1 }; 1 }, 'invalid value';
	::like $@, qr{isa check for "number" failed}, 'error msg';
};

subtest 'required attribute checks' => sub {
	package Local::XXX2;
	use Sub::Talisman::Struct
		XXX => [qw( +number! )],
	;

	::plan tests => 5;
	::ok eval q{ sub foo1 :XXX(123) { 1 }; 1 }, 'valid value';
	::ok !eval q{ sub foo2 :XXX { 1 }; 1 }, 'no value';
	::like $@, qr{Missing required arguments: number}, 'error msg - missing';
	::ok !eval q{ sub foo3 :XXX("Hello") { 1 }; 1 }, 'invalid value';
	::like $@, qr{isa check for "number" failed}, 'error msg - invalid';
};

subtest 'too many args' => sub {
	package Local::XXX3;
	use Sub::Talisman::Struct
		XXX => [qw( +number! )],
	;

	::plan tests => 3;
	::ok eval q{ sub foo1 :XXX(123) { 1 }; 1 }, 'valid value';
	::ok !eval q{ sub foo2 :XXX(123,456) { 1 }; 1 }, 'too many values';
	::like $@, qr{Too many parameters for attribute Local::XXX3::XXX}, 'error msg';
};

