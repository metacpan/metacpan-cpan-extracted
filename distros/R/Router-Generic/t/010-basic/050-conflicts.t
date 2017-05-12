#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Router::Generic');

ok(
  my $router = Router::Generic->new(),
  "Got router object"
);

# Test the ability of the router to detect when a conflict may arise:
LITERAL_PATH: {
  $router->add_route(
    name      => 'ExampleA1',
    path      => '/path/ExampleA1',
    target    => '/exampleA1.asp',
  );

  eval {
    $router->add_route(
      name      => 'ExampleA1',
      path      => '/another-path/ExampleA1',
      target    => '/another-exampleA1.asp',
    );
  };
  like $@, qr{^name\s+'ExampleA1'\s+is\s+already\s+in\s+use\s+},
    "Names are unique (A)";

  eval {
    $router->add_route(
      name      => 'ExampleA2',
      path      => '/path/ExampleA1',
      target    => '/exampleA1.asp',
    );
  };
  like $@, qr{^path\s+'\*\s+/path/ExampleA1}, "Paths are unique (A)";
};

NAMED_CAPTURE1: {
  $router->add_route(
    name      => 'ExampleB1',
    path      => '/path/:ExampleB1',
    target    => '/exampleB1.asp',
  );

  eval {
    $router->add_route(
      name      => 'ExampleB2',
      path      => '/path/:ExampleB1',
      target    => '/exampleB1.asp',
    );
  };
  like $@, qr{^path\s+'\*\s+/path/\:ExampleB1}, "Paths are unique (B)";
};


NAMED_CAPTURE2: {
  $router->add_route(
    name      => 'ExampleC1',
    path      => '/path2/{ExampleC1}',
    target    => '/exampleC1.asp',
  );

  eval {
    $router->add_route(
      name      => 'ExampleC2',
      path      => '/path2/{ExampleC1}',
      target    => '/exampleC1.asp',
    );
  };
  like $@, qr!^path\s+'\*\s+/path2/\{ExampleC1\}!, "Paths are unique (C1)";

  eval {
    $router->add_route(
      name      => 'ExampleC3',
      path      => '/path2/:ExampleC1',
      target    => '/exampleC1.asp',
    );
  };
  like $@, qr!^path\s+'/path2/\:ExampleC1!, "Paths are unique (C2)";
};


NAMED_WITH_REGEXP: {
  $router->add_route(
    name      => 'Zipcode',
    path      => '/place/{reg:\d{5}}',
    target    => '/zipcode.asp',
  );
  $router->add_route(
    name      => 'Areacode',
    path      => '/place/{reg:\d{3}}',
    target    => '/areacode.asp',
  );
  
  eval {
    $router->add_route(
      name      => 'FIPS',
      path      => '/place/{reg:\d{3}}',
      target    => '/fips.asp',
    );
  };
  like $@, qr!^path\s+'\*\s+/place/\{reg\:\\d\{3\}\}'\s+conflicts\s+with\s+pre\-existing\s+path\s+'\*\s+/place/\{reg\:\\d\{3\}\}'!, "Regexp captures are also unique";
};

