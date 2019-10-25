use Mojo::Base -strict;
use Test::More;
use Mojolicious::Command::bcrypt;

my $bcrypt = Mojolicious::Command::bcrypt->new;
ok $bcrypt->description, 'has a description';
ok $bcrypt->usage, 'has a usage';

done_testing;