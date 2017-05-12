use Test::More;

use Mojo::Server::Morbo::Backend::Inotify;

my  $b=Mojo::Server::Morbo::Backend::Inotify->new;

isa_ok $b, 'Mojo::Server::Morbo::Backend::Inotify', 'right class';

done_testing;
