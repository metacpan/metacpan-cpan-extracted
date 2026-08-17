use strict;
use warnings;
use Test::More;

use_ok 'Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap';
isa_ok 'Mojolicious::Plugin::Fondation::Perm::UI::Bootstrap', 'Mojolicious::Plugin';

done_testing;
