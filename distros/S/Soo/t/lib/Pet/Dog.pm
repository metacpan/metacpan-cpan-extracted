package Pet::Dog;

use parent "Pet";

use Soo;


has fly => { default => 'I cannot fly' };
has talk => { default => 'wow' };

1;