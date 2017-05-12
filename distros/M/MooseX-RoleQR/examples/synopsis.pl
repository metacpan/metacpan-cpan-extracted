use strict;
use warnings;

{
	package Local::Role;
	use MooseX::RoleQR;
	after qr{^gr} => sub {
		print " World\n";
	};
}
 
{
	package Local::Class;
	use Moose;
	with qw( Local::Role );
	sub greet {
		print "Hello";
	}
}
 
Local::Class->new->greet; # prints "Hello World\n"
