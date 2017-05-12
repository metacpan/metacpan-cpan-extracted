# vim: set ft=perl :

use strict;
use warnings;

use Test::More skip_all => 'XML storage engine is not implemented yet.';

use_ok('Repository::Simple::Engine::XML');
