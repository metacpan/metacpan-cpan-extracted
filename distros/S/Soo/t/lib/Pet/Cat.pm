package Pet::Cat;

use Soo;


extends 'Pet';

has fly => { default => 'I cannot fly' };
has talk => { default => 'meow' };

1;