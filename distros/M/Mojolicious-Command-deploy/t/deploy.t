use Test::More;
use Mojo::Base -strict;
use Mojolicious::Command::deploy;

ok +Mojolicious::Command::deploy->new->run;

done_testing;
