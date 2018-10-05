# t/001_load.t - check module loading, instantiation and attributes
use Test::More;

my $class = 'Mojolicious::Command::Author::generate::resources';
require_ok($class);
my $cmd = $class->new;
like($cmd->description, qr/ database tables$/, 'default description');
like($cmd->description, qr/ database tables$/, 'default description');
isa_ok($cmd->description('blah'), $class, 'chained setter');
is($cmd->description, 'blah', 'description setter works');
like($cmd->args, qr'HASH', 'args are a hash reference');
isa_ok($cmd->args({tables => ['fo']}), $class, 'chained setter');
is_deeply($cmd->args, {tables => ['fo']}, 'args setter works');
is_deeply(
          $cmd->routes->[0],
          {route => '/fo', via => ['GET'], name => 'home_fo', to => 'fo#index'},
          'right first route'
         );
isa_ok($cmd->app, 'Mojo::HelloWorld');

done_testing;

