# vim: set ft=perl :

use strict;
use warnings;

use Test::More skip_all => 'Table storage engine is not implemented yet.';

use_ok('Repository::Simple::Engine::Table');
