use Mojo::Base -strict;

use Test::More;

ok eval "require Mojolicious::Command::static; 1", "load Mojolicious::Command::static";

done_testing();
