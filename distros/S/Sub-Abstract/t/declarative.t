use strict;
use warnings;
use Test::Most;

# Test the declarative import form: use Sub::Abstract qw(method_name ...).
# No stub body is needed in this form.

local $ENV{HARNESS_ACTIVE}   = 0;
local $Sub::Abstract::BYPASS = 0;

{
	package Printer;
	use Sub::Abstract qw(print_doc);
	sub new { bless {}, shift }
}

{
	package LaserPrinter;
	our @ISA = ('Printer');
	sub new       { bless {}, shift }
	sub print_doc { 'laser output' }
}

{
	package InkjetPrinter;
	our @ISA = ('Printer');
	sub new { bless {}, shift }
	# InkjetPrinter does NOT implement print_doc
}

lives_and { is(LaserPrinter->new->print_doc, 'laser output') }
	'declarative form: implementing subclass: wrapper never fires';

throws_ok { InkjetPrinter->new->print_doc }
	qr/\Qprint_doc() is an abstract method of Printer and must be implemented by InkjetPrinter\E/,
	'declarative form: non-implementing subclass: croaks with correct message';

# Multiple method names in one import
{
	package Serializable;
	use Sub::Abstract qw(serialize deserialize);
	sub new { bless {}, shift }
}

{
	package JsonSerializable;
	our @ISA = ('Serializable');
	sub new         { bless {}, shift }
	sub serialize   { 'json' }
	sub deserialize { 'parsed' }
}

{
	package XmlSerializable;
	our @ISA = ('Serializable');
	sub new       { bless {}, shift }
	sub serialize { 'xml' }
	# deserialize not implemented
}

lives_ok { JsonSerializable->new->serialize   } 'declarative multi: first method implemented: ok';
lives_ok { JsonSerializable->new->deserialize } 'declarative multi: second method implemented: ok';

throws_ok { XmlSerializable->new->deserialize }
	qr/abstract method/,
	'declarative multi: missing method croaks';

done_testing;
