#!/usr/bin/env perl

use strictures 1;
use Plack::Builder;
use Plack::Middleware::Debug::DBIC::QueryLog;
use Plack::Middleware::DBIC::QueryLog;
use Test::DBIx::Class
  -schema_class => 'Example::Schema',
  qw(:resultsets);

User->create({email =>'jjnapiork@cpan.org'});
User->create({email =>'tester@test.org'});

builder {
  enable 'Debug', panels =>['DBIC::QueryLog', 'Memory'];
  sub {
    my $env = shift;
    my $schema = Schema->clone;
    my $querylog = Plack::Middleware::DBIC::QueryLog->get_querylog_from_env($env);

    $schema->storage->debug(1);
    $schema->storage->debugobj($querylog);

    return [
      200, ['Content-Type' =>'text/html'],
      [
        '<html>',
          '<head>',
            '<title>Hello World</title>',
          '</head>',
          '<body>',
            '<h1>Hello World</h1>',
            map({ '<p>'. $_->email. '</p>' } $schema->resultset('User')->all),
          '</body>',
        '</html>',
      ],
    ];
  };
};

## Dependent Modules: (Plack, DBIx::Class, Test::DBIx::Class, strictures).
## Example commandline: "plackup -I lib -I example/lib/ example/app.psgi".
