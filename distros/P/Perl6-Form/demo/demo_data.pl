use 5.010;
use warnings;

use Perl6::Form;

@names = (
	"King Lear",
	"The Three Witches",
	"Iago",
);

@roles = (
	"Protagonist",
	"Plot devices",
	"Villain",
);

@addresses = (
	"The Cliffs, Dover",
	"Dismal Forest, Scotland",
	"Casa d'Otello,  Venezia",
);

print form {interleave=>1},
	<<'EOFORMAT',
Name:    {[[[[[[[[[[[[[[[}   Role: {[[[[[[[[[[}
Address: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
_______________________________________________
EOFORMAT
	\@names, \@roles, \@addresses;

print form 
	<<'EOFORMAT',
Name:    {[[[[[[[[[[[[[[[}   Role: {[[[[[[[[[[}
Address: {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}
_______________________________________________
EOFORMAT
	\@names, \@roles, \@addresses;
