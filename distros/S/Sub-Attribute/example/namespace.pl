#!perl -w
use strict;

print "namespace comparison:\n";

system $^X, '-e', <<'CODE';
	use strict;
	{
		package AH;
		use Attribute::Handlers;

		sub Bar :ATTR(CODE){}
	}

	use Class::Inspector;
	use Data::Dumper;
	print "\nAttribute::Handlers\n";
	print Data::Dumper->Dump([Class::Inspector->methods('AH')], ['*MODULE']);
	print Data::Dumper->Dump([Class::Inspector->methods('UNIVERSAL')], ['*UNIVERSAL']);
CODE

system $^X, '-e', <<'CODE';
	use strict;
	{
		package SA;
		use Sub::Attribute;

		sub Foo :ATTR_SUB{}
	}

	use Class::Inspector;
	use Data::Dumper;
	print "\nSub::Attribute\n";
	print Data::Dumper->Dump([Class::Inspector->methods('SA')], ['*MODULE']);
	print Data::Dumper->Dump([Class::Inspector->methods('UNIVERSAL')], ['*UNIVERSAL']);
__END__
CODE
