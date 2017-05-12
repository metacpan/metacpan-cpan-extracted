#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';

use_ok('Router::Generic');

ok(
  my $router = Router::Generic->new(),
  "Got router object"
);

# Add 1,000 routes:
my $num = 1;
for my $outer ( 1..10 )
{
  for my $inner ( 1..100 )
  {
    print STDERR "\radd_route: $num/1000";
    $router->add_route(
      name      => "Speed$outer\_$inner",
      path      => "/path/{word:$outer\_$inner}",
      target    => "/foo.asp"
    );
    $num++;
  }# end for()
}# end for()

warn "\n";

$num = 1;
for my $outer ( 1..10 )
{
  for my $inner ( 1..100 )
  {
    print STDERR "\rmatch (uncached): $num/1000";
    $router->match("/path/$outer\_$inner/");
    $num++;
  }# end for()
}# end for()

warn "\n";

$num = 1;
for my $outer ( 1..10 )
{
  for my $inner ( 1..100 )
  {
    print STDERR "\rmatch (cached): $num/1000";
    $router->match("/path/$outer\_$inner/");
    $num++;
  }# end for()
}# end for()

warn "\n";

$num = 1;
for my $outer ( 1..10 )
{
  for my $inner ( 1..100 )
  {
    print STDERR "\ruri_for: $num/1000";
    $router->uri_for("Speed$outer\_$inner", { word => rand() });
    $num++;
  }# end for()
}# end for()

warn "\n";


