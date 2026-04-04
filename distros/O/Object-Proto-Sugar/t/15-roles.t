use Test::More;

{
	package Printable;

	use Object::Proto::Sugar -role;

	requires 'name';

	has format => (
	  is      => 'rw',
	  default => 'text',
	);

	sub print_self { $_[0]->name . ' (' . $_[0]->format . ')' }

	1;
}

{
	package Document;

	use Object::Proto::Sugar;

	with 'Printable';

	has name => (
	  is  => 'rw',
	  isa => 'Str',
	);

	1;
}

package main;

my $doc = new Document name => 'Report';

is($doc->name,       'Report', 'own slot works');
is($doc->format,     'text',   'role slot with default works');
is($doc->print_self, 'Report (text)', 'role method works');

ok(Object::Proto::does($doc, 'Printable'), 'does Printable');

$doc->format('html');
is($doc->format, 'html', 'role slot is writable');

done_testing();
