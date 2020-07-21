package Pet;

use strict;
use warnings;

use Soo;


has eat => { default => 'eating' };
has fly => { default => 'flying' };
has 'name';
has run => { default => 'running' };
has talk => { default => 'talking' };
has sleep => { default => 'sleeping' };

1;