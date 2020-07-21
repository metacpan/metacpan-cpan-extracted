package Pet::Parrot;

use Soo;


extends 'Pet';

has run => { default => 'I cannot run' };
has talk => { default => 'argh' };

1;